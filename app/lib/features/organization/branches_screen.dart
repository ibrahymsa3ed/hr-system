import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/api_client.dart';
import '../../core/auth_service.dart';
import '../../l10n/app_localizations.dart';

class BranchesScreen extends StatefulWidget {
  const BranchesScreen({super.key});

  @override
  State<BranchesScreen> createState() => _BranchesScreenState();
}

class _BranchesScreenState extends State<BranchesScreen> {
  List<dynamic> _branches = [];
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
      final res = await context.read<AuthService>().api.get('/branches');
      setState(() => _branches = res.data is List ? res.data : []);
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
    final code = TextEditingController(text: existing?['code'] ?? '');
    final lat = TextEditingController(text: '${existing?['latitude'] ?? ''}');
    final lng = TextEditingController(text: '${existing?['longitude'] ?? ''}');
    final radius = TextEditingController(text: '${existing?['geofence_radius_meters'] ?? ''}');
    final tz = TextEditingController(text: existing?['timezone'] ?? 'UTC');

    final ok = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
      title: Text(existing != null ? t.edit : t.add),
      content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: name, decoration: InputDecoration(labelText: t.name)),
        TextField(controller: nameAr, decoration: InputDecoration(labelText: t.nameAr)),
        TextField(controller: code, decoration: InputDecoration(labelText: t.code)),
        TextField(controller: lat, decoration: InputDecoration(labelText: t.latitude), keyboardType: TextInputType.number),
        TextField(controller: lng, decoration: InputDecoration(labelText: t.longitude), keyboardType: TextInputType.number),
        TextField(controller: radius, decoration: InputDecoration(labelText: t.geofenceRadius), keyboardType: TextInputType.number),
        TextField(controller: tz, decoration: InputDecoration(labelText: t.timezone)),
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
        'code': code.text.trim(),
        if (lat.text.trim().isNotEmpty) 'latitude': double.tryParse(lat.text.trim()),
        if (lng.text.trim().isNotEmpty) 'longitude': double.tryParse(lng.text.trim()),
        if (radius.text.trim().isNotEmpty) 'geofence_radius_meters': int.tryParse(radius.text.trim()),
        if (tz.text.trim().isNotEmpty) 'timezone': tz.text.trim(),
      };
      final api = context.read<AuthService>().api;
      if (existing != null) {
        await api.put('/branches/${existing['id']}', data: data);
      } else {
        await api.post('/branches', data: data);
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
      await context.read<AuthService>().api.delete('/branches/$id');
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
                child: _branches.isEmpty
                    ? ListView(children: [Center(child: Padding(padding: const EdgeInsets.all(32), child: Text(t.noData, style: TextStyle(color: Colors.grey.shade500))))])
                    : ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: _branches.length,
                        itemBuilder: (context, i) {
                          final b = _branches[i] as Map;
                          return Card(child: ListTile(
                            title: Text('${b['name']}'),
                            subtitle: Text('${t.code}: ${b['code']}  ${t.employees}: ${b['employees_count'] ?? 0}'),
                            trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                              IconButton(icon: const Icon(Icons.edit_outlined), onPressed: () => _edit(b)),
                              IconButton(icon: const Icon(Icons.delete_outline), onPressed: () => _delete(b['id'] as int)),
                            ]),
                            onTap: () => _edit(b),
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
