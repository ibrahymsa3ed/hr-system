<?php

namespace App\Services;

use App\Models\ApprovalStep;
use App\Models\User;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Support\Facades\DB;
use Illuminate\Validation\ValidationException;

/**
 * Drives multi-step approval chains defined in config('hr.approval_chains').
 * Works for any model using the Approvable trait (loans, leave, shift changes,
 * resignations). Steps are created up-front and advanced one role at a time.
 */
class ApprovalService
{
    /**
     * Create the ordered approval steps for an approvable from its chain.
     */
    public function start(Model $approvable, string $type): void
    {
        $chain = config("hr.approval_chains.{$type}");

        if (empty($chain)) {
            throw new \InvalidArgumentException("Unknown approval chain: {$type}");
        }

        foreach (array_values($chain) as $i => $role) {
            $approvable->approvalSteps()->create([
                'sequence' => $i + 1,
                'role' => $role,
                'status' => 'pending',
            ]);
        }
    }

    /**
     * Record an approver's decision on a step and advance/settle the chain.
     */
    public function decide(ApprovalStep $step, User $approver, bool $approved, ?string $note = null): ApprovalStep
    {
        return DB::transaction(function () use ($step, $approver, $approved, $note) {
            if ($step->status !== 'pending') {
                throw ValidationException::withMessages(['step' => 'This step has already been decided.']);
            }

            // Must be the earliest pending step (enforce sequence).
            $approvable = $step->approvable;
            $current = $approvable->currentApprovalStep();
            if (! $current || $current->id !== $step->id) {
                throw ValidationException::withMessages(['step' => 'An earlier step is still pending.']);
            }

            // Approver must hold the role this step requires.
            if (! $approver->hasRole($step->role)) {
                throw ValidationException::withMessages(['role' => "Requires the {$step->role} role."]);
            }

            $step->update([
                'status' => $approved ? 'approved' : 'rejected',
                'approver_user_id' => $approver->id,
                'decided_at' => now(),
                'note' => $note,
            ]);

            if (! $approved) {
                $this->settle($approvable, 'rejected');

                return $step;
            }

            // Approved: if no more pending steps, the request is fully approved.
            if (! $approvable->currentApprovalStep()) {
                $this->settle($approvable, 'approved');
            }

            return $step;
        });
    }

    /**
     * Set the request status and fire optional side-effects on the model.
     */
    protected function settle(Model $approvable, string $status): void
    {
        $approvable->forceFill(['status' => $status])->save();

        if ($status === 'approved' && method_exists($approvable, 'onApproved')) {
            $approvable->onApproved();
        }

        if ($status === 'rejected' && method_exists($approvable, 'onRejected')) {
            $approvable->onRejected();
        }
    }
}
