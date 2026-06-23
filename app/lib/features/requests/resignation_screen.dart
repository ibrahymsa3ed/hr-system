import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/api_client.dart';
import '../../core/auth_service.dart';
import '../../core/date_utils.dart' as du;
import '../../l10n/app_localizations.dart';

class ResignationScreen extends StatefulWidget {
  const ResignationScreen({super.key});

  @override
  State<ResignationScreen> createState() => _ResignationScreenState();
}

class _ResignationScreenState extends State<ResignationScreen> {
  List<dynamic> _items = [];
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
      final res = await context.read<AuthService>().api.get('/resignation-requests');
      setState(() => _items = (res.data['data'] as List?) ?? []);
    } catch (e) {
      setState(() => _error = ApiClient.errorMessage(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _submit() async {
    final t = AppLocalizations.of(context)!;
    final reason = TextEditingController();
    final lastDay = TextEditingController();

    final ok = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
      title: Text(t.newResignation),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: reason, decoration: InputDecoration(labelText: t.reason), maxLines: 3),
        const SizedBox(height: 8),
        TextField(
          controller: lastDay,
          readOnly: true,
          decoration: InputDecoration(labelText: t.lastWorkingDay, suffixIcon: const Icon(Icons.calendar_today)),
          onTap: () async {
            final d = await showDatePicker(context: ctx, firstDate: DateTime.now(), lastDate: DateTime(2030), initialDate: DateTime.now().add(const Duration(days: 30)));
            if (d != null) lastDay.text = d.toIso8601String().split('T').first;
          },
        ),
      ]),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: Text(t.cancel)),
        FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(t.submit)),
      ],
    ));
    if (ok != true) return;
    try {
      await context.read<AuthService>().api.post('/resignation-requests', data: {
        if (reason.text.trim().isNotEmpty) 'reason': reason.text.trim(),
        if (lastDay.text.trim().isNotEmpty) 'last_working_day': lastDay.text.trim(),
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
                          return Card(child: ListTile(
                            title: Text('${r['reason'] ?? t.resignation}'),
                            subtitle: Text('${t.lastWorkingDay}: ${du.fmtDate(r['last_working_day'])}'),
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
            label: Text(t.newResignation),
          ),
        ),
      ],
    );
  }
}
