<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\ApprovalStep;
use App\Services\ApprovalService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class ApprovalController extends Controller
{
    public function __construct(private readonly ApprovalService $approvals) {}

    /** Steps awaiting a decision from a role the current user holds. */
    public function pending(Request $request): JsonResponse
    {
        $roles = $request->user()->getRoleNames()->all();

        $steps = ApprovalStep::with('approvable.employee:id,full_code,first_name,last_name')
            ->where('status', 'pending')
            ->whereIn('role', $roles)
            ->orderBy('created_at')
            ->get()
            // Only surface the *current* (earliest pending) step of each request.
            ->filter(fn (ApprovalStep $s) => optional($s->approvable?->currentApprovalStep())->id === $s->id)
            ->values();

        return response()->json($steps);
    }

    public function decide(Request $request, ApprovalStep $step): JsonResponse
    {
        $data = $request->validate([
            'approved' => ['required', 'boolean'],
            'note' => ['nullable', 'string', 'max:1000'],
        ]);

        $this->approvals->decide($step, $request->user(), $data['approved'], $data['note'] ?? null);

        return response()->json([
            'message' => __('messages.approval_recorded'),
            'step' => $step->fresh(),
            'request' => $step->approvable()->first(),
        ]);
    }
}
