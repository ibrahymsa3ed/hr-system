import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/auth_service.dart';
import '../../core/locale_provider.dart';
import '../../l10n/app_localizations.dart';

class DrawerItem {
  const DrawerItem(this.key, this.label, this.icon);
  final String key;
  final String label;
  final IconData icon;
}

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key, required this.selected, required this.onSelect});
  final String selected;
  final void Function(String) onSelect;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final auth = context.watch<AuthService>();
    final roles = auth.roles;
    final isManager = auth.hasAnyRole(
        ['hr_admin', 'hr_director', 'section_manager', 'supervisor', 'finance']);
    final isHr = auth.hasAnyRole(['hr_admin', 'hr_director']);
    final canReview = auth.hasAnyRole(['hr_admin', 'hr_director', 'section_manager']);
    final canSupervise = auth.hasAnyRole(['hr_admin', 'hr_director', 'supervisor']);

    return Drawer(
      child: SafeArea(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(color: Theme.of(context).colorScheme.primary),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  const Icon(Icons.badge, size: 48, color: Colors.white),
                  const SizedBox(height: 8),
                  Text(auth.user?['name'] ?? '',
                      style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  Text(roles.join(', '),
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 12)),
                ],
              ),
            ),
            _tile(context, 'dashboard', t.dashboard, Icons.dashboard),
            const Divider(),
            _header(t.attendance),
            _tile(context, 'check_in_out', t.checkInOut, Icons.fingerprint),
            if (isManager)
              _tile(context, 'attendance_history', t.attendanceHistory, Icons.history),
            if (canSupervise)
              _tile(context, 'record_for_employee', t.recordForEmployee, Icons.person_add),
            if (isManager) ...[
              const Divider(),
              _header(t.employees),
              _tile(context, 'employees', t.employees, Icons.people),
            ],
            const Divider(),
            _header(t.requests),
            _tile(context, 'leave_requests', t.leaveRequests, Icons.beach_access),
            _tile(context, 'loan_requests', t.loanRequests, Icons.account_balance),
            _tile(context, 'resignation', t.resignation, Icons.exit_to_app),
            if (canSupervise)
              _tile(context, 'shift_change', t.shiftChangeRequests, Icons.schedule),
            if (isManager) ...[
              const Divider(),
              _tile(context, 'approvals', t.approvals, Icons.fact_check),
              const Divider(),
              _header(t.reports),
              _tile(context, 'daily_report', t.dailyReport, Icons.today),
              _tile(context, 'period_report', t.periodReport, Icons.date_range),
            ],
            const Divider(),
            _header(t.selfService),
            _tile(context, 'monthly_hours', t.monthlyHours, Icons.timer),
            _tile(context, 'my_salary', t.mySalary, Icons.payments),
            _tile(context, 'leave_balances', t.leaveBalances, Icons.event_available),
            if (canReview) ...[
              const Divider(),
              _tile(context, 'performance', t.performanceReview, Icons.trending_up),
            ],
            if (canReview) ...[
              const Divider(),
              _header(t.recruitment),
              _tile(context, 'vacancies', t.jobVacancies, Icons.work),
              _tile(context, 'candidates_list', t.candidates, Icons.person_search),
            ],
            if (isHr) ...[
              const Divider(),
              _header(t.organization),
              _tile(context, 'branches', t.branches, Icons.store),
              _tile(context, 'sections', t.sections, Icons.category),
            ],
            const Divider(),
            ListTile(
              leading: const Icon(Icons.translate),
              title: Text(t.language),
              onTap: () {
                context.read<LocaleProvider>().toggle();
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.logout),
              title: Text(t.logout),
              onTap: () => context.read<AuthService>().logout(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tile(BuildContext context, String key, String label, IconData icon) {
    final sel = selected == key;
    return ListTile(
      leading: Icon(icon, color: sel ? Theme.of(context).colorScheme.primary : null),
      title: Text(label, style: sel ? TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold) : null),
      selected: sel,
      onTap: () {
        onSelect(key);
        Navigator.pop(context);
      },
    );
  }

  Widget _header(String text) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Text(text, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey.shade600)),
    );
  }
}
