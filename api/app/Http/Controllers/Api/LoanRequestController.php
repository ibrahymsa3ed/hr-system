<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\LoanRequest;
use App\Services\ApprovalService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class LoanRequestController extends Controller
{
    public function __construct(private readonly ApprovalService $approvals) {}

    public function index(Request $request): JsonResponse
    {
        $query = LoanRequest::with('employee:id,full_code,first_name,last_name', 'approvalSteps');

        if ($request->user()->hasRole('employee') && ! $request->user()->hasAnyRole(['hr_admin', 'hr_director', 'finance'])) {
            $query->where('employee_id', optional($request->user()->employee)->id);
        }

        return response()->json($query->latest()->paginate($request->integer('per_page', 25)));
    }

    public function store(Request $request): JsonResponse
    {
        $employee = $request->user()->employee ?? abort(422, __('messages.not_an_employee'));

        $data = $request->validate([
            'type' => ['required', 'in:advance,long_term'],
            'amount' => ['required', 'numeric', 'min:1'],
            'installments' => ['nullable', 'integer', 'min:1', 'max:60'],
            'reason' => ['nullable', 'string', 'max:1000'],
        ]);
        $data['employee_id'] = $employee->id;

        $loan = LoanRequest::create($data);
        // 3-step chain: manager -> HR director -> finance.
        $this->approvals->start($loan, $loan->approvalType());

        return response()->json([
            'message' => __('messages.request_submitted'),
            'request' => $loan->load('approvalSteps'),
        ], 201);
    }

    public function show(LoanRequest $loanRequest): JsonResponse
    {
        return response()->json($loanRequest->load('employee', 'approvalSteps.approver:id,name'));
    }
}
