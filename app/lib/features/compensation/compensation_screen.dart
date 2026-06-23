import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/api_client.dart';
import '../../core/auth_service.dart';
import '../../l10n/app_localizations.dart';

class CompensationScreen extends StatefulWidget {
  const CompensationScreen({super.key, required this.employeeId});
  final int employeeId;

  @override
  State<CompensationScreen> createState() => _CompensationScreenState();
}

class _CompensationScreenState extends State<CompensationScreen> {
  List<dynamic> _records = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final res = await context.read<AuthService>().api.get('/employees/${widget.employeeId}/compensation');
      setState(() => _records = res.data is List ? res.data : []);
    } catch (e) {
      setState(() => _error = ApiClient.errorMessage(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _add() async {
    final t = AppLocalizations.of(context)!;
    final salary = TextEditingController();
    final date = TextEditingController();
    final note = TextEditingController();
    bool med = false, soc = false;

    final ok = await showDialog<bool>(context: context, builder: (ctx) => StatefulBuilder(
      builder: (ctx, setDlg) => AlertDialog(
        title: Text(t.add),
        content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: salary, decoration: InputDecoration(labelText: t.basicSalary), keyboardType: TextInputType.number),
          TextField(controller: date, decoration: InputDecoration(labelText: '${t.effectiveDate} (YYYY-MM-DD)')),
          SwitchListTile(title: Text(t.medicalInsurance), value: med, onChanged: (v) => setDlg(() => med = v)),
          SwitchListTile(title: Text(t.socialInsurance), value: soc, onChanged: (v) => setDlg(() => soc = v)),
          TextField(controller: note, decoration: InputDecoration(labelText: t.notes)),
        ])),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(t.cancel)),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(t.save)),
        ],
      ),
    ));
    if (ok != true) return;
    try {
      await context.read<AuthService>().api.post('/employees/${widget.employeeId}/compensation', data: {
        'basic_salary': double.tryParse(salary.text.trim()),
        'effective_date': date.text.trim(),
        'medical_insurance': med,
        'social_insurance': soc,
        if (note.text.trim().isNotEmpty) 'note': note.text.trim(),
      });
      await _load();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ApiClient.errorMessage(e))));
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(t.salaryHistory)),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : RefreshIndicator(
                  onRefresh: _load,
                  child: _records.isEmpty
                      ? ListView(children: [ListTile(title: Text(t.noData))])
                      : ListView.builder(
                          padding: const EdgeInsets.all(12),
                          itemCount: _records.length,
                          itemBuilder: (context, i) {
                            final r = _records[i] as Map;
                            return Card(child: ListTile(
                              leading: const Icon(Icons.payments),
                              title: Text('${t.basicSalary}: ${r['basic_salary'] ?? '-'}'),
                              subtitle: Text('${t.effectiveDate}: ${r['effective_date']}\n${r['note'] ?? ''}'),
                              trailing: Column(mainAxisSize: MainAxisSize.min, children: [
                                Icon(r['medical_insurance'] == true ? Icons.check_circle : Icons.cancel,
                                    color: r['medical_insurance'] == true ? Colors.green : Colors.grey, size: 18),
                                Icon(r['social_insurance'] == true ? Icons.check_circle : Icons.cancel,
                                    color: r['social_insurance'] == true ? Colors.green : Colors.grey, size: 18),
                              ]),
                            ));
                          },
                        ),
                ),
      floatingActionButton: FloatingActionButton(onPressed: _add, child: const Icon(Icons.add)),
    );
  }
}
