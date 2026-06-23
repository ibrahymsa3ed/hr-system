import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/api_client.dart';
import '../../core/auth_service.dart';
import '../../core/config.dart';
import '../../l10n/app_localizations.dart';
import 'employee_form_screen.dart';
import 'employee_documents.dart';
import '../compensation/compensation_screen.dart';

class EmployeeDetailScreen extends StatefulWidget {
  const EmployeeDetailScreen({super.key, required this.employeeId});
  final int employeeId;

  @override
  State<EmployeeDetailScreen> createState() => _EmployeeDetailScreenState();
}

class _EmployeeDetailScreenState extends State<EmployeeDetailScreen> {
  Map<String, dynamic>? _emp;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final res = await context.read<AuthService>().api.get('/employees/${widget.employeeId}');
      setState(() => _emp = (res.data as Map).cast<String, dynamic>());
    } catch (e) {
      setState(() => _error = ApiClient.errorMessage(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final auth = context.read<AuthService>();
    final isHr = auth.hasAnyRole(['hr_admin', 'hr_director']);
    final isHrOrFinance = auth.hasAnyRole(['hr_admin', 'hr_director', 'finance']);

    if (_error != null) return Scaffold(appBar: AppBar(), body: Center(child: Text(_error!)));
    if (_emp == null) return Scaffold(appBar: AppBar(), body: const Center(child: CircularProgressIndicator()));

    final e = _emp!;
    final section = e['section'] as Map?;
    final branch = e['branch'] as Map?;
    final docs = (e['documents'] as List?) ?? [];
    final shifts = (e['shift_schedules'] as List?) ?? [];
    final ledgers = (e['leave_ledgers'] as List?) ?? [];

    return Scaffold(
      appBar: AppBar(
        title: Text(e['full_name'] ?? '${e['first_name']} ${e['last_name']}'),
        actions: [
          if (isHr)
            IconButton(icon: const Icon(Icons.edit), onPressed: () async {
              await Navigator.push(context, MaterialPageRoute(
                builder: (_) => EmployeeFormScreen(employee: e),
              ));
              _load();
            }),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (e['photo_path'] != null)
              Center(child: CircleAvatar(radius: 50, backgroundImage: NetworkImage(
                Uri.parse(AppConfig.apiBaseUrl).replace(path: '/storage/${e['photo_path']}').toString(),
              ))),
            const SizedBox(height: 16),
            _infoCard(t, [
              _row(t.fullCode, e['full_code']),
              _row(t.branch, branch?['name']),
              _row(t.section, section?['name']),
              _row(t.employmentStatus, e['employment_status']),
              _row(t.phone, e['phone']),
              _row(t.email, e['email']),
              _row(t.gender, e['gender']),
              _row(t.dateOfBirth, e['date_of_birth']),
              _row(t.age, '${e['age'] ?? '-'}'),
              _row(t.hireDate, e['hire_date']),
              _row(t.hasMobile, e['has_mobile'] == true ? t.yes : t.no),
            ]),
            if (isHrOrFinance) ...[
              const SizedBox(height: 12),
              _infoCard(t, [
                _row(t.basicSalary, '${e['basic_salary'] ?? '-'}'),
                _row(t.nationalId, '${e['national_id'] ?? '-'}'),
                _row(t.medicalInsurance, e['medical_insurance'] == true ? t.yes : t.no),
                _row(t.socialInsurance, e['social_insurance'] == true ? t.yes : t.no),
              ]),
            ],
            if (ledgers.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(t.leaveBalances, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              for (final l in ledgers)
                Card(child: ListTile(
                  title: Text('${l['type']} (${l['year']})'),
                  subtitle: Text('${t.entitled}: ${l['entitled_days']}  ${t.used}: ${l['used_days']}'),
                  trailing: Text('${((l['entitled_days'] ?? 0) - (l['used_days'] ?? 0)).toStringAsFixed(1)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                )),
            ],
            if (shifts.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(t.workingHours, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              for (final s in shifts)
                Card(child: ListTile(
                  leading: Icon(s['is_active'] == true ? Icons.check_circle : Icons.circle_outlined,
                      color: s['is_active'] == true ? Colors.green : Colors.grey),
                  title: Text('${s['start_time']} - ${s['end_time']}'),
                  subtitle: Text('${t.workingDays}: ${s['work_days']}'),
                )),
            ],
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () => Navigator.push(context, MaterialPageRoute(
                builder: (_) => EmployeeDocumentsScreen(employeeId: widget.employeeId, documents: docs),
              )),
              icon: const Icon(Icons.folder),
              label: Text('${t.documents} (${docs.length})'),
            ),
            if (isHrOrFinance) ...[
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () => Navigator.push(context, MaterialPageRoute(
                  builder: (_) => CompensationScreen(employeeId: widget.employeeId),
                )),
                icon: const Icon(Icons.payments),
                label: Text(t.compensation),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _infoCard(AppLocalizations t, List<Widget> children) {
    return Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(children: children)));
  }

  Widget _row(String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(flex: 2, child: Text(label, style: const TextStyle(fontWeight: FontWeight.w500))),
          Expanded(flex: 3, child: Text('${value ?? '-'}')),
        ],
      ),
    );
  }
}
