import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/api_client.dart';
import '../../core/auth_service.dart';
import '../../core/location_service.dart';
import '../../l10n/app_localizations.dart';

class SupervisorRecordingScreen extends StatefulWidget {
  const SupervisorRecordingScreen({super.key});

  @override
  State<SupervisorRecordingScreen> createState() => _SupervisorRecordingScreenState();
}

class _SupervisorRecordingScreenState extends State<SupervisorRecordingScreen> {
  List<dynamic> _employees = [];
  int? _selectedId;
  bool _loading = true;
  bool _busy = false;
  String? _status;

  @override
  void initState() {
    super.initState();
    _loadEmployees();
  }

  Future<void> _loadEmployees() async {
    try {
      final res = await context.read<AuthService>().api.get('/employees', query: {'per_page': 200});
      setState(() {
        _employees = (res.data['data'] as List?) ?? [];
        _loading = false;
      });
    } catch (e) {
      setState(() { _loading = false; _status = ApiClient.errorMessage(e); });
    }
  }

  Future<void> _record(String action) async {
    if (_selectedId == null) return;
    setState(() { _busy = true; _status = null; });
    try {
      final pos = await LocationService.current();
      await context.read<AuthService>().api.post('/attendance/record', data: {
        'employee_id': _selectedId,
        'action': action,
        'latitude': pos.latitude,
        'longitude': pos.longitude,
      });
      final t = AppLocalizations.of(context)!;
      setState(() => _status = action == 'check_in' ? t.checkedIn : t.checkedOut);
    } catch (e) {
      setState(() => _status = ApiClient.errorMessage(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    if (_loading) return const Center(child: CircularProgressIndicator());

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DropdownButtonFormField<int>(
            decoration: InputDecoration(labelText: t.selectEmployee, border: const OutlineInputBorder()),
            value: _selectedId,
            items: _employees.map<DropdownMenuItem<int>>((e) {
              final emp = e as Map;
              return DropdownMenuItem(value: emp['id'] as int, child: Text('${emp['full_code']} - ${emp['first_name']} ${emp['last_name']}'));
            }).toList(),
            onChanged: (v) => setState(() => _selectedId = v),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: _busy || _selectedId == null ? null : () => _record('check_in'),
            icon: const Icon(Icons.login),
            label: Text(t.checkIn),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _busy || _selectedId == null ? null : () => _record('check_out'),
            icon: const Icon(Icons.logout),
            label: Text(t.checkOut),
          ),
          const SizedBox(height: 24),
          if (_busy) const Center(child: CircularProgressIndicator()),
          if (_status != null && !_busy) Text(_status!, textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyLarge),
        ],
      ),
    );
  }
}
