import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/api_client.dart';
import '../../core/auth_service.dart';
import '../../core/location_service.dart';
import '../../l10n/app_localizations.dart';

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  bool _busy = false;
  String? _status;

  Future<void> _punch(String path, String successMsg) async {
    final api = context.read<AuthService>().api;
    setState(() {
      _busy = true;
      _status = AppLocalizations.of(context)!.locating;
    });
    try {
      final pos = await LocationService.current();
      await api.post(path, data: {
        'latitude': pos.latitude,
        'longitude': pos.longitude,
      });
      setState(() => _status = successMsg);
    } catch (e) {
      setState(() => _status = ApiClient.errorMessage(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.location_on, size: 64, color: Color(0xFF1B5E20)),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _busy ? null : () => _punch('/attendance/check-in', t.checkedIn),
                icon: const Icon(Icons.login),
                label: Text(t.checkIn),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _busy ? null : () => _punch('/attendance/check-out', t.checkedOut),
                icon: const Icon(Icons.logout),
                label: Text(t.checkOut),
              ),
            ),
            const SizedBox(height: 24),
            if (_busy) const CircularProgressIndicator(),
            if (_status != null && !_busy)
              Text(_status!, textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge),
          ],
        ),
      ),
    );
  }
}
