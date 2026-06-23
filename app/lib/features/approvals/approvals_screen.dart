import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/api_client.dart';
import '../../core/auth_service.dart';
import '../../l10n/app_localizations.dart';

class ApprovalsScreen extends StatefulWidget {
  const ApprovalsScreen({super.key});

  @override
  State<ApprovalsScreen> createState() => _ApprovalsScreenState();
}

class _ApprovalsScreenState extends State<ApprovalsScreen> {
  List<dynamic> _steps = [];
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
      final res = await context.read<AuthService>().api.get('/approvals/pending');
      setState(() => _steps = (res.data as List?) ?? []);
    } catch (e) {
      setState(() => _error = ApiClient.errorMessage(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _decide(int stepId, bool approved) async {
    try {
      await context.read<AuthService>().api.post('/approvals/$stepId/decide', data: {'approved': approved});
      await _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ApiClient.errorMessage(e))));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) return Center(child: Text(_error!));

    return RefreshIndicator(
      onRefresh: _load,
      child: _steps.isEmpty
          ? ListView(children: [ListTile(title: Text(t.noData))])
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: _steps.length,
              itemBuilder: (context, i) {
                final step = _steps[i] as Map;
                final approvable = step['approvable'] as Map?;
                final employee = approvable?['employee'] as Map?;
                final title = '${approvable?['type'] ?? ''} '
                    '${approvable?['amount'] ?? approvable?['start_date'] ?? ''}'.trim();
                final who = employee == null
                    ? ''
                    : '${employee['full_code']} · ${employee['first_name']} ${employee['last_name']}';

                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title.isEmpty ? 'Request #${approvable?['id']}' : title,
                            style: Theme.of(context).textTheme.titleMedium),
                        if (who.isNotEmpty) Text(who),
                        Text('${t.status}: ${step['role']} (step ${step['sequence']})'),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(
                              onPressed: () => _decide(step['id'] as int, false),
                              child: Text(t.reject, style: const TextStyle(color: Colors.red)),
                            ),
                            const SizedBox(width: 8),
                            FilledButton(
                              onPressed: () => _decide(step['id'] as int, true),
                              child: Text(t.approve),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
