import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/locale_provider.dart';
import '../../l10n/app_localizations.dart';
import 'app_drawer.dart';
import '../approvals/approvals_screen.dart';
import '../attendance/attendance_screen.dart';
import '../attendance/attendance_history.dart';
import '../attendance/supervisor_recording.dart';
import '../dashboard/dashboard_screen.dart';
import '../employees/employees_screen.dart';
import '../requests/requests_screen.dart';
import '../requests/resignation_screen.dart';
import '../requests/shift_change_screen.dart';
import '../reports/daily_report_screen.dart';
import '../reports/period_report_screen.dart';
import '../self_service/monthly_hours_screen.dart';
import '../self_service/my_salary_screen.dart';
import '../self_service/leave_balances_screen.dart';
import '../performance/performance_screen.dart';
import '../recruitment/recruitment_screen.dart';
import '../organization/branches_screen.dart';
import '../organization/sections_screen.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  String _page = 'dashboard';

  String _pageTitle(AppLocalizations t) => switch (_page) {
        'dashboard' => t.dashboard,
        'check_in_out' => t.checkInOut,
        'attendance_history' => t.attendanceHistory,
        'record_for_employee' => t.recordForEmployee,
        'employees' => t.employees,
        'leave_requests' => t.leaveRequests,
        'loan_requests' => t.loanRequests,
        'resignation' => t.resignation,
        'shift_change' => t.shiftChangeRequests,
        'approvals' => t.approvals,
        'daily_report' => t.dailyReport,
        'period_report' => t.periodReport,
        'monthly_hours' => t.monthlyHours,
        'my_salary' => t.mySalary,
        'leave_balances' => t.leaveBalances,
        'performance' => t.performanceReview,
        'vacancies' => t.jobVacancies,
        'candidates_list' => t.candidates,
        'branches' => t.branches,
        'sections' => t.sections,
        _ => t.appTitle,
      };

  Widget _body() => switch (_page) {
        'dashboard' => const DashboardScreen(),
        'check_in_out' => const AttendanceScreen(),
        'attendance_history' => const AttendanceHistoryScreen(),
        'record_for_employee' => const SupervisorRecordingScreen(),
        'employees' => const EmployeesScreen(),
        'leave_requests' => const RequestsScreen(tab: 'leave'),
        'loan_requests' => const RequestsScreen(tab: 'loan'),
        'resignation' => const ResignationScreen(),
        'shift_change' => const ShiftChangeScreen(),
        'approvals' => const ApprovalsScreen(),
        'daily_report' => const DailyReportScreen(),
        'period_report' => const PeriodReportScreen(),
        'monthly_hours' => const MonthlyHoursScreen(),
        'my_salary' => const MySalaryScreen(),
        'leave_balances' => const LeaveBalancesScreen(),
        'performance' => const PerformanceScreen(),
        'vacancies' => const RecruitmentScreen(tab: 'vacancies'),
        'candidates_list' => const RecruitmentScreen(tab: 'candidates'),
        'branches' => const BranchesScreen(),
        'sections' => const SectionsScreen(),
        _ => const DashboardScreen(),
      };

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(_pageTitle(t)),
        actions: [
          IconButton(
            tooltip: t.language,
            onPressed: () => context.read<LocaleProvider>().toggle(),
            icon: const Icon(Icons.translate),
          ),
        ],
      ),
      drawer: AppDrawer(
        selected: _page,
        onSelect: (key) => setState(() => _page = key),
      ),
      body: _body(),
    );
  }
}
