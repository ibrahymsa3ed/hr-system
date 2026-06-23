import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/api_client.dart';
import '../../core/auth_service.dart';
import '../../l10n/app_localizations.dart';

class SectionsScreen extends StatefulWidget {
  const SectionsScreen({super.key});

  @override
  State<SectionsScreen> createState() => _SectionsScreenState();
}

class _SectionsScreenState extends State<SectionsScreen> {
  List<dynamic> _sections = [];
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
      final res = await context.read<AuthService>().api.get('/sections');
      setState(() => _sections = res.data is List ? res.data : []);
    } catch (e) {
      setState(() => _error = ApiClient.errorMessage(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _edit([Map? existing]) async {
    final t = AppLocalizations.of(context)!;
    final name = TextEditingController(text: existing?['name'] ?? '');
    final nameAr = TextEditingController(text: existing?['name_ar'] ?? '');
    final mainCode = TextEditingController(text: existing?['main_code'] ?? '');
    final desc = TextEditingController(text: existing?['description'] ?? '');

    final ok = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
      title: Text(existing != null ? t.edit : t.add),
      content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: name, decoration: InputDecoration(labelText: t.name)),
        TextField(controller: nameAr, decoration: InputDecoration(labelText: t.nameAr)),
        TextField(controller: mainCode, decoration: InputDecoration(labelText: t.mainCode)),
        TextField(controller: desc, decoration: InputDecoration(labelText: t.description), maxLines: 2),
      ])),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: Text(t.cancel)),
        FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(t.save)),
      ],
    ));
    if (ok != true) return;
    try {
      final data = {
        'name': name.text.trim(),
        if (nameAr.text.trim().isNotEmpty) 'name_ar': nameAr.text.trim(),
        'main_code': mainCode.text.trim(),
        if (desc.text.trim().isNotEmpty) 'description': desc.text.trim(),
      };
      final api = context.read<AuthService>().api;
      if (existing != null) {
        await api.put('/sections/${existing['id']}', data: data);
      } else {
        await api.post('/sections', data: data);
      }
      await _load();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ApiClient.errorMessage(e))));
    }
  }

  Future<void> _delete(int id) async {
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
      await context.read<AuthService>().api.delete('/sections/$id');
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
                child: _sections.isEmpty
                    ? ListView(children: [Center(child: Padding(padding: const EdgeInsets.all(32), child: Text(t.noData, style: TextStyle(color: Colors.grey.shade500))))])
                    : ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: _sections.length,
                        itemBuilder: (context, i) {
                          final s = _sections[i] as Map;
                          return Card(child: ListTile(
                            leading: CircleAvatar(child: Text('${s['main_code']}')),
                            title: Text('${s['name']}'),
                            subtitle: Text('${t.employees}: ${s['employees_count'] ?? 0}'),
                            trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                              IconButton(icon: const Icon(Icons.edit_outlined), onPressed: () => _edit(s)),
                              IconButton(icon: const Icon(Icons.delete_outline), onPressed: () => _delete(s['id'] as int)),
                            ]),
                            onTap: () => _edit(s),
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
          child: FloatingActionButton(onPressed: () => _edit(), child: const Icon(Icons.add)),
        ),
      ],
    );
  }
}
