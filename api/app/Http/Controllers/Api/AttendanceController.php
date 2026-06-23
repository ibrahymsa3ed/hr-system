<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\AttendanceRecord;
use App\Models\Employee;
use App\Services\AttendanceService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class AttendanceController extends Controller
{
    public function __construct(private readonly AttendanceService $attendance) {}

    /** Listing for managers/HR, filterable by date range, branch, employee. */
    public function index(Request $request): JsonResponse
    {
        $records = AttendanceRecord::query()
            ->with('employee:id,full_code,first_name,last_name,branch_id,section_id')
            ->when($request->employee_id, fn ($q, $v) => $q->where('employee_id', $v))
            ->when($request->from, fn ($q, $v) => $q->whereDate('work_date', '>=', $v))
            ->when($request->to, fn ($q, $v) => $q->whereDate('work_date', '<=', $v))
            ->when($request->branch_id, fn ($q, $v) => $q->whereHas('employee', fn ($e) => $e->where('branch_id', $v)))
            ->orderByDesc('work_date')
            ->paginate($request->integer('per_page', 50));

        return response()->json($records);
    }

    /** Self check-in (employee app, GPS validated against branch geofence). */
    public function checkIn(Request $request): JsonResponse
    {
        $data = $this->coords($request);
        $employee = $this->currentEmployee($request);

        $record = $this->attendance->checkIn($employee, $data['latitude'], $data['longitude']);

        return response()->json(['message' => __('messages.checked_in'), 'record' => $record]);
    }

    public function checkOut(Request $request): JsonResponse
    {
        $data = $this->coords($request);
        $employee = $this->currentEmployee($request);

        $record = $this->attendance->checkOut($employee, $data['latitude'], $data['longitude']);

        return response()->json(['message' => __('messages.checked_out'), 'record' => $record]);
    }

    /**
     * Supervisor records attendance for an employee (company policy allows this
     * for staff without a mobile phone). Restricted to supervisor/HR roles.
     */
    public function recordForEmployee(Request $request): JsonResponse
    {
        $data = $request->validate([
            'employee_id' => ['required', 'exists:employees,id'],
            'action' => ['required', 'in:check_in,check_out'],
            'latitude' => ['required', 'numeric', 'between:-90,90'],
            'longitude' => ['required', 'numeric', 'between:-180,180'],
        ]);

        $employee = Employee::findOrFail($data['employee_id']);
        $recorder = $request->user();

        $record = $data['action'] === 'check_in'
            ? $this->attendance->checkIn($employee, $data['latitude'], $data['longitude'], $recorder)
            : $this->attendance->checkOut($employee, $data['latitude'], $data['longitude'], $recorder);

        return response()->json(['record' => $record]);
    }

    private function coords(Request $request): array
    {
        return $request->validate([
            'latitude' => ['required', 'numeric', 'between:-90,90'],
            'longitude' => ['required', 'numeric', 'between:-180,180'],
        ]);
    }

    private function currentEmployee(Request $request): Employee
    {
        return $request->user()->employee ?? abort(422, __('messages.not_an_employee'));
    }
}
