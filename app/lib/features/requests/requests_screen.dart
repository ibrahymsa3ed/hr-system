import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/api_client.dart';
import '../../core/auth_service.dart';
import '../../core/date_utils.dart' as du;
import '../../l10n/app_localizations.dart';

class RequestsScreen extends StatefulWidget {
  const RequestsScreen({super.key, this.tab = 'leave'});
  final String tab;

  @override
  State<RequestsScreen> createState() => _RequestsScreenState();
}

class _RequestsScreenState extends State<RequestsScreen> {
  List<dynamic> _leave = [];
  List<dynamic> _loans = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    final api = context.read<AuthService>().api;
    try {
      final leave = await api.get('/leave-requests');
      final loans = await api.get('/loan-requests');
      setState(() {
        _leave = (leave.data['data'] as List?) ?? [];
        _loans = (loans.data['data'] as List?) ?? [];
      });
    } catch (e) {
      setState(() => _error = ApiClient.errorMessage(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _newLeave() async {
    final t = AppLocalizations.of(context)!;
    String type = 'annual';
    final start = TextEditingController();
    final end = TextEditingController();
    final reason = TextEditingController();

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(t.newLeave),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: type,
                decoration: InputDecoration(labelText: t.type),
                items: [
                  DropdownMenuItem(value: 'annual', child: Text(t.annualLeave)),
                  DropdownMenuItem(value: 'sick', child: Text(t.sickLeave)),
                  DropdownMenuItem(value: 'unpaid', child: Text(t.unpaidLeave)),
                  DropdownMenuItem(value: 'day_off', child: Text(t.dayOff)),
                  DropdownMenuItem(value: 'permission', child: Text(t.permission)),
                ],
                onChanged: (v) => type = v ?? 'annual',
              ),
              const SizedBox(height: 8),
              TextField(
                controller: start,
                readOnly: true,
                decoration: InputDecoration(labelText: t.startDate, suffixIcon: const Icon(Icons.calendar_today)),
                onTap: () async {
                  final d = await showDatePicker(context: ctx, firstDate: DateTime(2020), lastDate: DateTime(2030), initialDate: DateTime.now());
                  if (d != null) start.text = d.toIso8601String().split('T').first;
                },
              ),
              TextField(
                controller: end,
                readOnly: true,
                decoration: InputDecoration(labelText: t.endDate, suffixIcon: const Icon(Icons.calendar_today)),
                onTap: () async {
                  final d = await showDatePicker(context: ctx, firstDate: DateTime(2020), lastDate: DateTime(2030), initialDate: DateTime.now());
                  if (d != null) end.text = d.toIso8601String().split('T').first;
                },
              ),
              TextField(controller: reason, decoration: InputDecoration(labelText: t.reason)),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(t.cancel)),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(t.submit)),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    try {
      await context.read<AuthService>().api.post('/leave-requests', data: {
        'type': type,
        'start_date': start.text.trim(),
        if (end.text.trim().isNotEmpty) 'end_date': end.text.trim(),
        if (reason.text.trim().isNotEmpty) 'reason': reason.text.trim(),
      });
      await _load();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ApiClient.errorMessage(e))));
    }
  }

  Future<void> _newLoan() async {
    final t = AppLocalizations.of(context)!;
    String type = 'advance';
    final amount = TextEditingController();
    final installments = TextEditingController(text: '1');
    final reason = TextEditingController();

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(t.newLoan),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: type,
                decoration: InputDecoration(labelText: t.type),
                items: [
                  DropdownMenuItem(value: 'advance', child: Text(t.advance)),
                  DropdownMenuItem(value: 'long_term', child: Text(t.longTerm)),
                ],
                onChanged: (v) => type = v ?? 'advance',
              ),
              const SizedBox(height: 8),
              TextField(controller: amount, decoration: InputDecoration(labelText: t.amount), keyboardType: TextInputType.number),
              TextField(controller: installments, decoration: InputDecoration(labelText: t.installments), keyboardType: TextInputType.number),
              TextField(controller: reason, decoration: InputDecoration(labelText: t.reason)),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(t.cancel)),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(t.submit)),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    try {
      await context.read<AuthService>().api.post('/loan-requests', data: {
        'type': type,
        'amount': double.tryParse(amount.text.trim()) ?? 0,
        'installments': int.tryParse(installments.text.trim()) ?? 1,
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
    final showLeave = widget.tab == 'leave';

    final body = _loading
        ? const Center(child: CircularProgressIndicator())
        : _error != null
            ? Center(child: Text(_error!))
            : RefreshIndicator(
                onRefresh: _load,
                child: ListView(
                  padding: const EdgeInsets.all(12),
                  children: showLeave
                      ? [
                          if (_leave.isEmpty) Center(child: Padding(padding: const EdgeInsets.all(32), child: Text(t.noData, style: TextStyle(color: Colors.grey.shade500)))),
                          for (final r in _leave)
                            _RequestTile(title: '${r['type']}', subtitle: '${du.fmtDate(r['start_date'])} → ${du.fmtDate(r['end_date'])}', status: '${r['status']}'),
                        ]
                      : [
                          if (_loans.isEmpty) Center(child: Padding(padding: const EdgeInsets.all(32), child: Text(t.noData, style: TextStyle(color: Colors.grey.shade500)))),
                          for (final r in _loans)
                            _RequestTile(title: '${r['type']}', subtitle: '${r['amount']}  (${r['installments']} ${t.installments})', status: '${r['status']}'),
                        ],
                ),
              );

    return Stack(
      children: [
        body,
        Positioned(
          bottom: 16,
          right: 16,
          child: FloatingActionButton.extended(
            onPressed: showLeave ? _newLeave : _newLoan,
            icon: const Icon(Icons.add),
            label: Text(showLeave ? t.newLeave : t.newLoan),
          ),
        ),
      ],
    );
  }
}

class _RequestTile extends StatelessWidget {
  const _RequestTile({required this.title, required this.subtitle, required this.status});
  final String title, subtitle, status;

  Color _color() => switch (status) {
        'approved' => Colors.green,
        'rejected' => Colors.red,
        _ => Colors.orange,
      };

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: Chip(label: Text(status), backgroundColor: _color().withValues(alpha: 0.15)),
      ),
    );
  }
}
