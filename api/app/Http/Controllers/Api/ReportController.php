<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\AttendanceRecord;
use App\Models\Employee;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class ReportController extends Controller
{
    /** Daily report: attendance snapshot for a single date. */
    public function daily(Request $request): JsonResponse
    {
        $date = $request->date('date')?->toDateString() ?? now()->toDateString();

        $records = AttendanceRecord::with('employee:id,full_code,first_name,last_name,branch_id,section_id')
            ->whereDate('work_date', $date)
            ->when($request->branch_id, fn ($q, $v) => $q->whereHas('employee', fn ($e) => $e->where('branch_id', $v)))
            ->when($request->section_id, fn ($q, $v) => $q->whereHas('employee', fn ($e) => $e->where('section_id', $v)))
            ->get();

        return response()->json(['date' => $date, 'records' => $records]);
    }

    /**
     * Period report: per-employee aggregates across a date range covering
     * attendance, lateness, overtime, working hours, leave by type, salary,
     * insurance, age and remaining papers.
     */
    public function period(Request $request): JsonResponse
    {
        $data = $request->validate([
            'from' => ['required', 'date'],
            'to' => ['required', 'date', 'after_or_equal:from'],
            'branch_id' => ['nullable', 'exists:branches,id'],
            'section_id' => ['nullable', 'exists:sections,id'],
            'employee_id' => ['nullable', 'exists:employees,id'],
        ]);

        $canSeeSalary = $request->user()->hasAnyRole(['hr_admin', 'hr_director', 'finance']);

        $employees = Employee::query()
            ->with(['section:id,name,main_code'])
            ->withCount(['documents as remaining_papers' => fn ($q) => $q->where('is_submitted', false)])
            ->when($data['branch_id'] ?? null, fn ($q, $v) => $q->where('branch_id', $v))
            ->when($data['section_id'] ?? null, fn ($q, $v) => $q->where('section_id', $v))
            ->when($data['employee_id'] ?? null, fn ($q, $v) => $q->where('id', $v))
            ->get();

        $rows = $employees->map(function (Employee $e) use ($data, $canSeeSalary) {
            $att = $e->attendanceRecords()
                ->whereDate('work_date', '>=', $data['from'])
                ->whereDate('work_date', '<=', $data['to'])->get();

            $leaves = $e->leaveRequests()
                ->where('status', 'approved')
                ->whereDate('start_date', '>=', $data['from'])
                ->whereDate('start_date', '<=', $data['to'])->get();

            return [
                'employee_id' => $e->id,
                'full_code' => $e->full_code,
                'name' => $e->full_name,
                'section' => $e->section?->name,
                'age' => $e->age,
                'present_days' => $att->whereNotNull('check_in_at')->count(),
                'absent_days' => $att->where('status', 'absent')->count(),
                'late_count' => $att->where('late_minutes', '>', 0)->count(),
                'total_late_minutes' => (int) $att->sum('late_minutes'),
                'overtime_minutes' => (int) $att->sum('overtime_minutes'),
                'working_hours' => round($att->sum('worked_minutes') / 60, 1),
                'leave_days' => [
                    'annual' => (float) $leaves->where('type', 'annual')->sum('days'),
                    'sick' => (float) $leaves->where('type', 'sick')->sum('days'),
                    'unpaid' => (float) $leaves->where('type', 'unpaid')->sum('days'),
                    'day_off' => (float) $leaves->where('type', 'day_off')->sum('days'),
                ],
                'permissions' => $leaves->where('type', 'permission')->count(),
                'medical_insurance' => $e->medical_insurance,
                'social_insurance' => $e->social_insurance,
                'remaining_papers' => $e->remaining_papers,
                'basic_salary' => $canSeeSalary ? $e->basic_salary : null,
            ];
        });

        return response()->json(['from' => $data['from'], 'to' => $data['to'], 'rows' => $rows]);
    }
}
