import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/api_client.dart';
import '../../core/auth_service.dart';
import '../../l10n/app_localizations.dart';
import 'employee_detail_screen.dart';
import 'employee_form_screen.dart';

class EmployeesScreen extends StatefulWidget {
  const EmployeesScreen({super.key});

  @override
  State<EmployeesScreen> createState() => _EmployeesScreenState();
}

class _EmployeesScreenState extends State<EmployeesScreen> {
  List<dynamic> _employees = [];
  bool _loading = true;
  String? _error;
  int _page = 1;
  bool _hasMore = true;
  final _search = TextEditingController();
  final _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    _load();
    _scroll.addListener(() {
      if (_scroll.position.pixels >= _scroll.position.maxScrollExtent - 200 && !_loading && _hasMore) {
        _page++;
        _loadMore();
      }
    });
  }

  @override
  void dispose() {
    _scroll.dispose();
    _search.dispose();
    super.dispose();
  }

  Future<void> _load([String? search]) async {
    _page = 1;
    _hasMore = true;
    setState(() { _loading = true; _error = null; });
    try {
      final res = await context.read<AuthService>().api.get('/employees', query: {
        if (search != null && search.isNotEmpty) 'search': search,
        'page': _page,
      });
      final data = res.data as Map;
      setState(() {
        _employees = (data['data'] as List?) ?? [];
        _hasMore = (data['next_page_url'] != null);
      });
    } catch (e) {
      setState(() => _error = ApiClient.errorMessage(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loadMore() async {
    try {
      final res = await context.read<AuthService>().api.get('/employees', query: {
        if (_search.text.trim().isNotEmpty) 'search': _search.text.trim(),
        'page': _page,
      });
      final data = res.data as Map;
      setState(() {
        _employees.addAll((data['data'] as List?) ?? []);
        _hasMore = (data['next_page_url'] != null);
      });
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final isHr = context.read<AuthService>().hasAnyRole(['hr_admin', 'hr_director']);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: TextField(
            controller: _search,
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search),
              hintText: t.search,
              border: const OutlineInputBorder(),
              suffixIcon: IconButton(icon: const Icon(Icons.clear), onPressed: () { _search.clear(); _load(); }),
            ),
            onSubmitted: _load,
          ),
        ),
        Expanded(
          child: _loading && _employees.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : _error != null
                  ? Center(child: Text(_error!))
                  : RefreshIndicator(
                      onRefresh: () => _load(_search.text.trim()),
                      child: ListView.builder(
                        controller: _scroll,
                        itemCount: _employees.length + (_hasMore ? 1 : 0),
                        itemBuilder: (context, i) {
                          if (i >= _employees.length) {
                            return const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator()));
                          }
                          final e = _employees[i] as Map;
                          final section = e['section'] as Map?;
                          return Card(
                            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            child: ListTile(
                              leading: CircleAvatar(child: Text('${e['full_code']}'.split('-').last)),
                              title: Text('${e['first_name']} ${e['last_name']}'),
                              subtitle: Text('${e['full_code']} · ${section?['name'] ?? ''}'),
                              trailing: Text('${e['employment_status']}'),
                              onTap: () async {
                                await Navigator.push(context, MaterialPageRoute(
                                  builder: (_) => EmployeeDetailScreen(employeeId: e['id'] as int),
                                ));
                                _load(_search.text.trim());
                              },
                            ),
                          );
                        },
                      ),
                    ),
        ),
        if (isHr)
          Padding(
            padding: const EdgeInsets.all(12),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () async {
                  final result = await Navigator.push(context, MaterialPageRoute(builder: (_) => const EmployeeFormScreen()));
                  if (result == true) _load(_search.text.trim());
                },
                icon: const Icon(Icons.person_add),
                label: Text(t.addEmployee),
              ),
            ),
          ),
      ],
    );
  }
}
