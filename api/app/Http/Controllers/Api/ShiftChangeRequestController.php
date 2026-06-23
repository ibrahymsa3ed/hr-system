<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\ShiftChangeRequest;
use App\Services\ApprovalService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class ShiftChangeRequestController extends Controller
{
    public function __construct(private readonly ApprovalService $approvals) {}

    public function index(Request $request): JsonResponse
    {
        return response()->json(
            ShiftChangeRequest::with('employee:id,full_code,first_name,last_name', 'approvalSteps')
                ->latest()->paginate($request->integer('per_page', 25))
        );
    }

    /** Raised by a restaurant manager/supervisor; HR approval auto-applies hours. */
    public function store(Request $request): JsonResponse
    {
        $data = $request->validate([
            'employee_id' => ['required', 'exists:employees,id'],
            'proposed_work_days' => ['required', 'array'],
            'proposed_work_days.*' => ['integer', 'between:0,6'],
            'proposed_start_time' => ['required', 'date_format:H:i'],
            'proposed_end_time' => ['required', 'date_format:H:i'],
            'proposed_break_minutes' => ['nullable', 'integer', 'min:0'],
            'effective_from' => ['nullable', 'date'],
            'reason' => ['nullable', 'string', 'max:1000'],
        ]);
        $data['requested_by_user_id'] = $request->user()->id;

        $req = ShiftChangeRequest::create($data);
        $this->approvals->start($req, ShiftChangeRequest::APPROVAL_TYPE);

        return response()->json([
            'message' => __('messages.request_submitted'),
            'request' => $req->load('approvalSteps'),
        ], 201);
    }
}
