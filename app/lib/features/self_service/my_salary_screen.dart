import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/api_client.dart';
import '../../core/auth_service.dart';
import '../../l10n/app_localizations.dart';

class MySalaryScreen extends StatefulWidget {
  const MySalaryScreen({super.key});

  @override
  State<MySalaryScreen> createState() => _MySalaryScreenState();
}

class _MySalaryScreenState extends State<MySalaryScreen> {
  Map<String, dynamic>? _data;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final res = await context.read<AuthService>().api.get('/me/salary');
      setState(() => _data = (res.data as Map).cast<String, dynamic>());
    } catch (e) {
      setState(() => _error = ApiClient.errorMessage(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    if (_error != null) return Center(child: Text(_error!));
    if (_data == null) return const Center(child: CircularProgressIndicator());

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Card(child: ListTile(
            leading: Icon(Icons.payments, color: Theme.of(context).colorScheme.primary, size: 40),
            title: Text(t.basicSalary),
            trailing: Text('${_data!['basic_salary'] ?? '-'}', style: Theme.of(context).textTheme.headlineSmall),
          )),
          const SizedBox(height: 12),
          Card(child: ListTile(
            leading: const Icon(Icons.local_hospital),
            title: Text(t.medicalInsurance),
            trailing: Icon(_data!['medical_insurance'] == true ? Icons.check_circle : Icons.cancel,
                color: _data!['medical_insurance'] == true ? Colors.green : Colors.grey),
          )),
          Card(child: ListTile(
            leading: const Icon(Icons.security),
            title: Text(t.socialInsurance),
            trailing: Icon(_data!['social_insurance'] == true ? Icons.check_circle : Icons.cancel,
                color: _data!['social_insurance'] == true ? Colors.green : Colors.grey),
          )),
        ],
      ),
    );
  }
}
