import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/api_client.dart';
import '../../core/auth_service.dart';
import '../../l10n/app_localizations.dart';

class ShiftChangeScreen extends StatefulWidget {
  const ShiftChangeScreen({super.key});

  @override
  State<ShiftChangeScreen> createState() => _ShiftChangeScreenState();
}

class _ShiftChangeScreenState extends State<ShiftChangeScreen> {
  List<dynamic> _items = [];
  List<dynamic> _employees = [];
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
      final api = context.read<AuthService>().api;
      final res = await api.get('/shift-change-requests');
      final empRes = await api.get('/employees', query: {'per_page': 200});
      setState(() {
        _items = (res.data['data'] as List?) ?? [];
        _employees = (empRes.data['data'] as List?) ?? [];
      });
    } catch (e) {
      setState(() => _error = ApiClient.errorMessage(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _submit() async {
    final t = AppLocalizations.of(context)!;
    int? empId;
    final startTime = TextEditingController(text: '09:00');
    final endTime = TextEditingController(text: '17:00');
    final breakMin = TextEditingController(text: '60');
    List<int> workDays = [0, 1, 2, 3, 4];
    final reason = TextEditingController();

    final ok = await showDialog<bool>(context: context, builder: (ctx) => StatefulBuilder(
      builder: (ctx, setDlg) => AlertDialog(
        title: Text(t.shiftChange),
        content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
          DropdownButtonFormField<int>(
            decoration: InputDecoration(labelText: t.selectEmployee),
            items: _employees.map<DropdownMenuItem<int>>((e) {
              final emp = e as Map;
              return DropdownMenuItem(value: emp['id'] as int, child: Text('${emp['full_code']} - ${emp['first_name']} ${emp['last_name']}'));
            }).toList(),
            onChanged: (v) => empId = v,
          ),
          const SizedBox(height: 8),
          TextField(controller: startTime, decoration: InputDecoration(labelText: t.proposedStartTime)),
          TextField(controller: endTime, decoration: InputDecoration(labelText: t.proposedEndTime)),
          TextField(controller: breakMin, decoration: InputDecoration(labelText: t.breakMinutes), keyboardType: TextInputType.number),
          const SizedBox(height: 8),
          Wrap(spacing: 4, children: List.generate(7, (i) {
            final labels = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
            final selected = workDays.contains(i);
            return FilterChip(label: Text(labels[i]), selected: selected, onSelected: (v) {
              setDlg(() { if (v) workDays.add(i); else workDays.remove(i); });
            });
          })),
          TextField(controller: reason, decoration: InputDecoration(labelText: t.reason)),
        ])),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(t.cancel)),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(t.submit)),
        ],
      ),
    ));
    if (ok != true || empId == null) return;
    try {
      await context.read<AuthService>().api.post('/shift-change-requests', data: {
        'employee_id': empId,
        'proposed_work_days': workDays..sort(),
        'proposed_start_time': startTime.text.trim(),
        'proposed_end_time': endTime.text.trim(),
        'proposed_break_minutes': int.tryParse(breakMin.text.trim()) ?? 0,
        if (reason.text.trim().isNotEmpty) 'reason': reason.text.trim(),
      });
      await _load();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ApiClient.errorMessage(e))));
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final body = _loading
        ? const Center(child: CircularProgressIndicator())
        : _error != null
            ? Center(child: Text(_error!))
            : RefreshIndicator(
                onRefresh: _load,
                child: _items.isEmpty
                    ? ListView(children: [Center(child: Padding(padding: const EdgeInsets.all(32), child: Text(t.noData, style: TextStyle(color: Colors.grey.shade500))))])
                    : ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: _items.length,
                        itemBuilder: (context, i) {
                          final r = _items[i] as Map;
                          final emp = r['employee'] as Map?;
                          return Card(child: ListTile(
                            title: Text(emp != null ? '${emp['full_code']} - ${emp['first_name']} ${emp['last_name']}' : 'Employee #${r['employee_id']}'),
                            subtitle: Text('${r['proposed_start_time']} - ${r['proposed_end_time']}  Days: ${r['proposed_work_days']}'),
                            trailing: Chip(label: Text('${r['status']}')),
                          ));
                        },
                      ),
              );

    return Stack(
      children: [
        body,
        Positioned(
          bottom: 16,
          right: 16,
          child: FloatingActionButton.extended(
            onPressed: _submit,
            icon: const Icon(Icons.add),
            label: Text(t.newRequest),
          ),
        ),
      ],
    );
  }
}
