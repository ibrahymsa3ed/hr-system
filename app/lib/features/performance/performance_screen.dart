import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/api_client.dart';
import '../../core/auth_service.dart';
import '../../l10n/app_localizations.dart';

class PerformanceScreen extends StatefulWidget {
  const PerformanceScreen({super.key});

  @override
  State<PerformanceScreen> createState() => _PerformanceScreenState();
}

class _PerformanceScreenState extends State<PerformanceScreen> {
  List<dynamic> _reviews = [];
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
      final res = await context.read<AuthService>().api.get('/performance-reviews');
      setState(() => _reviews = (res.data['data'] as List?) ?? []);
    } catch (e) {
      setState(() => _error = ApiClient.errorMessage(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _create() async {
    final t = AppLocalizations.of(context)!;
    final api = context.read<AuthService>().api;

    List<dynamic> employees = [];
    try {
      final res = await api.get('/employees', query: {'per_page': 200});
      employees = (res.data['data'] as List?) ?? [];
    } catch (_) {}

    int? empId;
    final period = TextEditingController(text: '${DateTime.now().year}-Q${((DateTime.now().month - 1) ~/ 3) + 1}');
    final score = TextEditingController();
    final evaluation = TextEditingController();
    String turnover = 'low';
    String status = 'draft';

    if (!mounted) return;
    final ok = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
      title: Text(t.performanceReview),
      content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
        DropdownButtonFormField<int>(
          decoration: InputDecoration(labelText: t.selectEmployee),
          items: employees.map<DropdownMenuItem<int>>((e) {
            final emp = e as Map;
            return DropdownMenuItem(value: emp['id'] as int, child: Text('${emp['full_code']} - ${emp['first_name']} ${emp['last_name']}'));
          }).toList(),
          onChanged: (v) => empId = v,
        ),
        const SizedBox(height: 8),
        TextField(controller: period, decoration: InputDecoration(labelText: t.period)),
        TextField(controller: score, decoration: InputDecoration(labelText: t.score), keyboardType: TextInputType.number),
        TextField(controller: evaluation, decoration: InputDecoration(labelText: t.managerEvaluation), maxLines: 3),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          decoration: InputDecoration(labelText: t.turnoverRisk),
          value: turnover,
          items: [
            DropdownMenuItem(value: 'low', child: Text(t.low)),
            DropdownMenuItem(value: 'medium', child: Text(t.medium)),
            DropdownMenuItem(value: 'high', child: Text(t.high)),
          ],
          onChanged: (v) => turnover = v ?? 'low',
        ),
        DropdownButtonFormField<String>(
          decoration: InputDecoration(labelText: t.status),
          value: status,
          items: [
            DropdownMenuItem(value: 'draft', child: Text(t.draft)),
            DropdownMenuItem(value: 'submitted', child: Text(t.submitted)),
            DropdownMenuItem(value: 'acknowledged', child: Text(t.acknowledged)),
          ],
          onChanged: (v) => status = v ?? 'draft',
        ),
      ])),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: Text(t.cancel)),
        FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(t.save)),
      ],
    ));
    if (ok != true || empId == null) return;
    try {
      await api.post('/performance-reviews', data: {
        'employee_id': empId,
        'period': period.text.trim(),
        'score': double.tryParse(score.text.trim()),
        'manager_evaluation': evaluation.text.trim().isNotEmpty ? evaluation.text.trim() : null,
        'turnover_risk': turnover,
        'status': status,
      });
      await _load();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ApiClient.errorMessage(e))));
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final canCreate = context.read<AuthService>().hasAnyRole(['hr_admin', 'hr_director', 'section_manager']);

    final body = _loading
        ? const Center(child: CircularProgressIndicator())
        : _error != null
            ? Center(child: Text(_error!))
            : RefreshIndicator(
                onRefresh: _load,
                child: _reviews.isEmpty
                    ? ListView(children: [Center(child: Padding(padding: const EdgeInsets.all(32), child: Text(t.noData, style: TextStyle(color: Colors.grey.shade500))))])
                    : ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: _reviews.length,
                        itemBuilder: (context, i) {
                          final r = _reviews[i] as Map;
                          final emp = r['employee'] as Map?;
                          return Card(child: ListTile(
                            leading: CircleAvatar(child: Text('${r['score'] ?? '-'}', style: const TextStyle(fontSize: 12))),
                            title: Text(emp != null ? '${emp['full_code']} ${emp['first_name']} ${emp['last_name']}' : '-'),
                            subtitle: Text('${r['period']}  ${t.turnoverRisk}: ${r['turnover_risk'] ?? '-'}'),
                            trailing: Chip(label: Text('${r['status']}')),
                          ));
                        },
                      ),
              );

    return Stack(
      children: [
        body,
        if (canCreate) Positioned(
          bottom: 16,
          right: 16,
          child: FloatingActionButton.extended(onPressed: _create, icon: const Icon(Icons.add), label: Text(t.add)),
        ),
      ],
    );
  }
}
