<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\ApprovalStep;
use App\Models\AttendanceRecord;
use App\Models\Branch;
use App\Models\Employee;
use App\Models\Section;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class DashboardController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $today = now()->toDateString();

        // Per-section totals + grand total (the "total and sections" requirement).
        $bySection = Section::withCount('employees')->get()
            ->map(fn ($s) => [
                'section_id' => $s->id,
                'main_code' => $s->main_code,
                'name' => $s->name,
                'name_ar' => $s->name_ar,
                'employees' => $s->employees_count,
            ]);

        $byBranch = Branch::withCount('employees')->get()
            ->map(fn ($b) => [
                'branch_id' => $b->id,
                'name' => $b->name,
                'employees' => $b->employees_count,
            ]);

        $todayAttendance = AttendanceRecord::where('work_date', $today)->get();

        // Pending approvals waiting on a role the current user holds.
        $roles = $request->user()->getRoleNames()->all();
        $pendingApprovals = ApprovalStep::where('status', 'pending')
            ->whereIn('role', $roles)
            ->count();

        return response()->json([
            'totals' => [
                'employees' => Employee::count(),
                'active_employees' => Employee::where('employment_status', 'active')->count(),
                'branches' => Branch::count(),
                'sections' => Section::count(),
            ],
            'by_section' => $bySection,
            'by_branch' => $byBranch,
            'today' => [
                'present' => $todayAttendance->whereNotNull('check_in_at')->count(),
                'late' => $todayAttendance->where('late_minutes', '>', 0)->count(),
                'on_leave' => $todayAttendance->where('status', 'leave')->count(),
                'checked_out' => $todayAttendance->whereNotNull('check_out_at')->count(),
            ],
            'pending_approvals' => $pendingApprovals,
        ]);
    }
}
