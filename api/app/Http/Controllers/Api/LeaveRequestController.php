<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\LeaveRequest;
use App\Services\ApprovalService;
use Carbon\Carbon;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Validation\ValidationException;

class LeaveRequestController extends Controller
{
    public function __construct(private readonly ApprovalService $approvals) {}

    public function index(Request $request): JsonResponse
    {
        $query = LeaveRequest::with('employee:id,full_code,first_name,last_name', 'approvalSteps');

        // Employees only see their own; managers/HR see all.
        if ($request->user()->hasRole('employee') && ! $request->user()->hasAnyRole(['hr_admin', 'hr_director'])) {
            $query->where('employee_id', optional($request->user()->employee)->id);
        }

        return response()->json($query->latest()->paginate($request->integer('per_page', 25)));
    }

    public function store(Request $request): JsonResponse
    {
        $employee = $request->user()->employee ?? abort(422, __('messages.not_an_employee'));

        $data = $request->validate([
            'type' => ['required', 'in:annual,unpaid,sick,day_off,permission'],
            'start_date' => ['required', 'date'],
            'end_date' => ['nullable', 'date', 'after_or_equal:start_date'],
            'start_time' => ['nullable', 'date_format:H:i'],
            'end_time' => ['nullable', 'date_format:H:i'],
            'reason' => ['nullable', 'string', 'max:1000'],
        ]);

        $data['employee_id'] = $employee->id;
        $data['days'] = $this->days($data);

        $this->checkOverlap($employee->id, $data);
        $this->checkBalance($employee, $data);

        $leave = LeaveRequest::create($data);
        $this->approvals->start($leave, $leave->approvalType());

        return response()->json([
            'message' => __('messages.request_submitted'),
            'request' => $leave->load('approvalSteps'),
        ], 201);
    }

    public function show(LeaveRequest $leaveRequest): JsonResponse
    {
        return response()->json($leaveRequest->load('employee', 'approvalSteps.approver:id,name'));
    }

    private function days(array $data): float
    {
        if ($data['type'] === 'permission' || empty($data['end_date'])) {
            return $data['type'] === 'permission' ? 0 : 1;
        }

        return Carbon::parse($data['start_date'])->diffInDays(Carbon::parse($data['end_date'])) + 1;
    }

    private function checkOverlap(int $employeeId, array $data): void
    {
        if (empty($data['end_date'])) {
            return;
        }

        $exists = LeaveRequest::where('employee_id', $employeeId)
            ->whereNotIn('status', ['rejected', 'cancelled'])
            ->where('start_date', '<=', $data['end_date'])
            ->where(fn ($q) => $q->where('end_date', '>=', $data['start_date'])->orWhereNull('end_date'))
            ->exists();

        if ($exists) {
            throw ValidationException::withMessages([
                'start_date' => __('messages.leave_overlap'),
            ]);
        }
    }

    private function checkBalance($employee, array $data): void
    {
        if ($data['type'] === 'unpaid' || $data['type'] === 'permission' || $data['days'] <= 0) {
            return;
        }

        $year = Carbon::parse($data['start_date'])->year;
        $ledger = $employee->leaveLedgers()
            ->where('year', $year)
            ->where('type', $data['type'])
            ->first();

        $entitled = $ledger?->entitled_days ?? config("hr.leave_entitlements.{$data['type']}", 0);
        $used = $ledger?->used_days ?? 0;

        if (($used + $data['days']) > $entitled) {
            throw ValidationException::withMessages([
                'type' => __('messages.insufficient_leave_balance', [
                    'remaining' => round($entitled - $used, 1),
                ]),
            ]);
        }
    }
}
