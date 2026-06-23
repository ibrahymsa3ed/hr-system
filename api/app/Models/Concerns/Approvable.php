<?php

namespace App\Models\Concerns;

use App\Models\ApprovalStep;
use Illuminate\Database\Eloquent\Relations\MorphMany;

/**
 * Adds a generic, sequenced approval trail to any model. The ApprovalService
 * creates the ordered steps from config('hr.approval_chains') and advances them.
 */
trait Approvable
{
    public function approvalSteps(): MorphMany
    {
        return $this->morphMany(ApprovalStep::class, 'approvable')->orderBy('sequence');
    }

    /** The next step awaiting a decision, or null if none pending. */
    public function currentApprovalStep(): ?ApprovalStep
    {
        return $this->approvalSteps()->where('status', 'pending')->orderBy('sequence')->first();
    }

    public function isFullyApproved(): bool
    {
        return $this->approvalSteps()->count() > 0
            && $this->approvalSteps()->where('status', '!=', 'approved')->count() === 0;
    }

    public function isRejected(): bool
    {
        return $this->approvalSteps()->where('status', 'rejected')->exists();
    }
}
