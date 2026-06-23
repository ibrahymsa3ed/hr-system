import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/api_client.dart';
import '../../core/auth_service.dart';
import '../../l10n/app_localizations.dart';

class EmployeeDocumentsScreen extends StatefulWidget {
  const EmployeeDocumentsScreen({super.key, required this.employeeId, required this.documents});
  final int employeeId;
  final List<dynamic> documents;

  @override
  State<EmployeeDocumentsScreen> createState() => _EmployeeDocumentsScreenState();
}

class _EmployeeDocumentsScreenState extends State<EmployeeDocumentsScreen> {
  late List<dynamic> _docs;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _docs = List.from(widget.documents);
  }

  Future<void> _reload() async {
    try {
      final res = await context.read<AuthService>().api.get('/employees/${widget.employeeId}/documents');
      setState(() => _docs = res.data is List ? res.data : []);
    } catch (_) {}
  }

  Future<void> _add() async {
    final t = AppLocalizations.of(context)!;
    final name = TextEditingController();
    final nameAr = TextEditingController();
    final ok = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
      title: Text(t.add),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: name, decoration: InputDecoration(labelText: t.name)),
        TextField(controller: nameAr, decoration: InputDecoration(labelText: t.nameAr)),
      ]),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: Text(t.cancel)),
        FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(t.save)),
      ],
    ));
    if (ok != true || name.text.trim().isEmpty) return;
    setState(() => _busy = true);
    try {
      await context.read<AuthService>().api.post('/employees/${widget.employeeId}/documents', data: {
        'name': name.text.trim(),
        if (nameAr.text.trim().isNotEmpty) 'name_ar': nameAr.text.trim(),
      });
      await _reload();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ApiClient.errorMessage(e))));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _toggleSubmitted(Map doc) async {
    try {
      await context.read<AuthService>().api.put(
        '/employees/${widget.employeeId}/documents/${doc['id']}',
        data: {'is_submitted': !(doc['is_submitted'] == true)},
      );
      await _reload();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ApiClient.errorMessage(e))));
    }
  }

  Future<void> _delete(int docId) async {
    final t = AppLocalizations.of(context)!;
    final ok = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
      title: Text(t.confirmDelete),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: Text(t.no)),
        FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(t.yes)),
      ],
    ));
    if (ok != true) return;
    try {
      await context.read<AuthService>().api.delete('/employees/${widget.employeeId}/documents/$docId');
      await _reload();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ApiClient.errorMessage(e))));
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(t.remainingPapers)),
      body: _docs.isEmpty
          ? Center(child: Text(t.noData))
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: _docs.length,
              itemBuilder: (context, i) {
                final d = _docs[i] as Map;
                return Card(
                  child: ListTile(
                    leading: Checkbox(value: d['is_submitted'] == true, onChanged: (_) => _toggleSubmitted(d)),
                    title: Text('${d['name']}'),
                    subtitle: d['name_ar'] != null ? Text('${d['name_ar']}') : null,
                    trailing: IconButton(icon: const Icon(Icons.delete_outline), onPressed: () => _delete(d['id'] as int)),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(onPressed: _busy ? null : _add, child: const Icon(Icons.add)),
    );
  }
}
