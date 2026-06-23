<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

/** Endpoints an employee is allowed to use about their own record. */
class SelfServiceController extends Controller
{
    /** Monthly attendance summary (total hours) for the logged-in employee. */
    public function monthlyReport(Request $request): JsonResponse
    {
        $employee = $request->user()->employee ?? abort(422, __('messages.not_an_employee'));

        $month = $request->input('month', now()->format('Y-m'));
        [$year, $m] = array_pad(explode('-', $month), 2, now()->month);
        $start = "{$year}-{$m}-01";
        $end = date('Y-m-t', strtotime($start));

        $att = $employee->attendanceRecords()->whereBetween('work_date', [$start, $end])->get();

        return response()->json([
            'month' => $month,
            'total_hours' => round($att->sum('worked_minutes') / 60, 1),
            'present_days' => $att->whereNotNull('check_in_at')->count(),
            'late_count' => $att->where('late_minutes', '>', 0)->count(),
            'overtime_hours' => round($att->sum('overtime_minutes') / 60, 1),
        ]);
    }

    /** The employee's own basic salary + insurance. */
    public function salary(Request $request): JsonResponse
    {
        $employee = $request->user()->employee ?? abort(422, __('messages.not_an_employee'));
        $employee->makeVisible('basic_salary');

        return response()->json([
            'basic_salary' => $employee->basic_salary,
            'medical_insurance' => $employee->medical_insurance,
            'social_insurance' => $employee->social_insurance,
        ]);
    }

    /** The employee's leave balances. */
    public function leaveBalances(Request $request): JsonResponse
    {
        $employee = $request->user()->employee ?? abort(422, __('messages.not_an_employee'));

        return response()->json(
            $employee->leaveLedgers()->where('year', now()->year)->get()
                ->map(fn ($l) => [
                    'type' => $l->type,
                    'entitled' => $l->entitled_days,
                    'used' => $l->used_days,
                    'remaining' => $l->remainingDays(),
                ])
        );
    }
}
