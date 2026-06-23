import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/api_client.dart';
import '../../core/auth_service.dart';
import '../../l10n/app_localizations.dart';

class RecruitmentScreen extends StatefulWidget {
  const RecruitmentScreen({super.key, this.tab = 'vacancies'});
  final String tab;

  @override
  State<RecruitmentScreen> createState() => _RecruitmentScreenState();
}

class _RecruitmentScreenState extends State<RecruitmentScreen> {
  List<dynamic> _items = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  bool get _isVacancies => widget.tab == 'vacancies';
  String get _endpoint => _isVacancies ? '/job-vacancies' : '/candidates';

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final res = await context.read<AuthService>().api.get(_endpoint);
      setState(() => _items = (res.data['data'] as List?) ?? []);
    } catch (e) {
      setState(() => _error = ApiClient.errorMessage(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _addVacancy() async {
    final t = AppLocalizations.of(context)!;
    final title = TextEditingController();
    final titleAr = TextEditingController();
    final desc = TextEditingController();
    final openings = TextEditingController(text: '1');

    final ok = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
      title: Text(t.vacancy),
      content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: title, decoration: InputDecoration(labelText: t.title)),
        TextField(controller: titleAr, decoration: InputDecoration(labelText: t.titleAr)),
        TextField(controller: desc, decoration: InputDecoration(labelText: t.description), maxLines: 3),
        TextField(controller: openings, decoration: InputDecoration(labelText: t.openings), keyboardType: TextInputType.number),
      ])),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: Text(t.cancel)),
        FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(t.save)),
      ],
    ));
    if (ok != true) return;
    try {
      await context.read<AuthService>().api.post('/job-vacancies', data: {
        'title': title.text.trim(),
        if (titleAr.text.trim().isNotEmpty) 'title_ar': titleAr.text.trim(),
        if (desc.text.trim().isNotEmpty) 'description': desc.text.trim(),
        'openings': int.tryParse(openings.text.trim()) ?? 1,
      });
      await _load();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ApiClient.errorMessage(e))));
    }
  }

  Future<void> _addCandidate() async {
    final t = AppLocalizations.of(context)!;
    final api = context.read<AuthService>().api;

    List<dynamic> vacancies = [];
    try {
      final res = await api.get('/job-vacancies', query: {'per_page': 100});
      vacancies = (res.data['data'] as List?) ?? [];
    } catch (_) {}

    int? vacancyId;
    final name = TextEditingController();
    final email = TextEditingController();
    final phone = TextEditingController();

    if (!mounted) return;
    final ok = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
      title: Text(t.candidates),
      content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
        DropdownButtonFormField<int>(
          decoration: InputDecoration(labelText: t.vacancy),
          items: vacancies.map<DropdownMenuItem<int>>((v) {
            final vac = v as Map;
            return DropdownMenuItem(value: vac['id'] as int, child: Text('${vac['title']}'));
          }).toList(),
          onChanged: (v) => vacancyId = v,
        ),
        TextField(controller: name, decoration: InputDecoration(labelText: t.name)),
        TextField(controller: email, decoration: InputDecoration(labelText: t.email)),
        TextField(controller: phone, decoration: InputDecoration(labelText: t.phone)),
      ])),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: Text(t.cancel)),
        FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(t.save)),
      ],
    ));
    if (ok != true || vacancyId == null) return;
    try {
      await api.post('/candidates', data: {
        'job_vacancy_id': vacancyId,
        'name': name.text.trim(),
        if (email.text.trim().isNotEmpty) 'email': email.text.trim(),
        if (phone.text.trim().isNotEmpty) 'phone': phone.text.trim(),
      });
      await _load();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ApiClient.errorMessage(e))));
    }
  }

  void _showCandidateDetail(Map candidate) {
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => _CandidateDetailScreen(candidateId: candidate['id'] as int),
    ));
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
                          final item = _items[i] as Map;
                          if (_isVacancies) {
                            return Card(child: ListTile(
                              title: Text('${item['title']}'),
                              subtitle: Text('${t.openings}: ${item['openings']}  ${t.candidates}: ${item['candidates_count'] ?? 0}'),
                              trailing: Chip(label: Text('${item['status']}')),
                            ));
                          } else {
                            return Card(child: ListTile(
                              title: Text('${item['name']}'),
                              subtitle: Text('${item['email'] ?? ''}  ${item['phone'] ?? ''}'),
                              trailing: Chip(label: Text('${item['stage']}')),
                              onTap: () => _showCandidateDetail(item),
                            ));
                          }
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
            onPressed: _isVacancies ? _addVacancy : _addCandidate,
            icon: const Icon(Icons.add),
            label: Text(t.add),
          ),
        ),
      ],
    );
  }
}

class _CandidateDetailScreen extends StatefulWidget {
  const _CandidateDetailScreen({required this.candidateId});
  final int candidateId;

  @override
  State<_CandidateDetailScreen> createState() => _CandidateDetailScreenState();
}

class _CandidateDetailScreenState extends State<_CandidateDetailScreen> {
  Map<String, dynamic>? _data;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final res = await context.read<AuthService>().api.get('/candidates/${widget.candidateId}');
      setState(() => _data = (res.data as Map).cast<String, dynamic>());
    } catch (e) {
      setState(() => _error = ApiClient.errorMessage(e));
    }
  }

  Future<void> _scheduleInterview() async {
    final t = AppLocalizations.of(context)!;
    final date = TextEditingController();
    String mode = 'onsite';
    final notes = TextEditingController();

    final ok = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
      title: Text(t.scheduleInterview),
      content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: date, decoration: InputDecoration(labelText: '${t.scheduledAt} (YYYY-MM-DD HH:mm)')),
        DropdownButtonFormField<String>(
          value: mode, decoration: InputDecoration(labelText: t.mode),
          items: [
            DropdownMenuItem(value: 'onsite', child: Text(t.onsite)),
            DropdownMenuItem(value: 'phone', child: Text(t.phoneCall)),
            DropdownMenuItem(value: 'video', child: Text(t.videoCall)),
          ],
          onChanged: (v) => mode = v ?? 'onsite',
        ),
        TextField(controller: notes, decoration: InputDecoration(labelText: t.notes), maxLines: 2),
      ])),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: Text(t.cancel)),
        FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(t.save)),
      ],
    ));
    if (ok != true) return;
    try {
      await context.read<AuthService>().api.post('/candidates/${widget.candidateId}/interviews', data: {
        if (date.text.trim().isNotEmpty) 'scheduled_at': date.text.trim(),
        'mode': mode,
        if (notes.text.trim().isNotEmpty) 'notes': notes.text.trim(),
      });
      await _load();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ApiClient.errorMessage(e))));
    }
  }

  Future<void> _evaluate() async {
    final t = AppLocalizations.of(context)!;
    final score = TextEditingController();
    String rec = 'hire';
    final notes = TextEditingController();

    final ok = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
      title: Text(t.evaluate),
      content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: score, decoration: InputDecoration(labelText: t.score), keyboardType: TextInputType.number),
        DropdownButtonFormField<String>(
          value: rec, decoration: InputDecoration(labelText: t.recommendation),
          items: [
            DropdownMenuItem(value: 'hire', child: Text(t.hire)),
            DropdownMenuItem(value: 'hold', child: Text(t.hold)),
            DropdownMenuItem(value: 'reject', child: Text(t.reject)),
          ],
          onChanged: (v) => rec = v ?? 'hire',
        ),
        TextField(controller: notes, decoration: InputDecoration(labelText: t.notes), maxLines: 2),
      ])),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: Text(t.cancel)),
        FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(t.save)),
      ],
    ));
    if (ok != true) return;
    try {
      await context.read<AuthService>().api.post('/candidates/${widget.candidateId}/evaluations', data: {
        'score': double.tryParse(score.text.trim()),
        'recommendation': rec,
        if (notes.text.trim().isNotEmpty) 'notes': notes.text.trim(),
      });
      await _load();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ApiClient.errorMessage(e))));
    }
  }

  Future<void> _hire() async {
    final t = AppLocalizations.of(context)!;
    final api = context.read<AuthService>().api;

    List<dynamic> branches = [], sections = [];
    try {
      final b = await api.get('/branches');
      final s = await api.get('/sections');
      branches = b.data is List ? b.data : [];
      sections = s.data is List ? s.data : [];
    } catch (_) {}

    int? branchId, sectionId;
    final subCode = TextEditingController();
    final nameParts = (_data?['name']?.toString() ?? '').split(' ');
    final firstName = TextEditingController(text: nameParts.isNotEmpty ? nameParts.first : '');
    final lastName = TextEditingController(text: nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '');

    if (!mounted) return;
    final ok = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
      title: Text(t.hire),
      content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: firstName, decoration: InputDecoration(labelText: t.firstName)),
        TextField(controller: lastName, decoration: InputDecoration(labelText: t.lastName)),
        DropdownButtonFormField<int>(
          decoration: InputDecoration(labelText: t.branch),
          items: branches.map<DropdownMenuItem<int>>((b) => DropdownMenuItem(value: (b as Map)['id'] as int, child: Text('${b['name']}'))).toList(),
          onChanged: (v) => branchId = v,
        ),
        DropdownButtonFormField<int>(
          decoration: InputDecoration(labelText: t.section),
          items: sections.map<DropdownMenuItem<int>>((s) => DropdownMenuItem(value: (s as Map)['id'] as int, child: Text('${s['main_code']} - ${s['name']}'))).toList(),
          onChanged: (v) => sectionId = v,
        ),
        TextField(controller: subCode, decoration: InputDecoration(labelText: t.subCode)),
      ])),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: Text(t.cancel)),
        FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(t.hire)),
      ],
    ));
    if (ok != true || branchId == null || sectionId == null) return;
    try {
      await api.post('/candidates/${widget.candidateId}/hire', data: {
        'branch_id': branchId,
        'section_id': sectionId,
        'sub_code': subCode.text.trim(),
        'first_name': firstName.text.trim(),
        'last_name': lastName.text.trim(),
      });
      if (mounted) { Navigator.pop(context); }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ApiClient.errorMessage(e))));
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    if (_error != null) return Scaffold(appBar: AppBar(), body: Center(child: Text(_error!)));
    if (_data == null) return Scaffold(appBar: AppBar(), body: const Center(child: CircularProgressIndicator()));

    final interviews = (_data!['interviews'] as List?) ?? [];
    final evaluations = (_data!['evaluations'] as List?) ?? [];

    return Scaffold(
      appBar: AppBar(title: Text('${_data!['name']}')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(children: [
            _row(t.email, _data!['email']),
            _row(t.phone, _data!['phone']),
            _row(t.stage, _data!['stage']),
          ]))),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(child: OutlinedButton.icon(onPressed: _scheduleInterview, icon: const Icon(Icons.calendar_today), label: Text(t.scheduleInterview))),
            const SizedBox(width: 8),
            Expanded(child: OutlinedButton.icon(onPressed: _evaluate, icon: const Icon(Icons.rate_review), label: Text(t.evaluate))),
          ]),
          const SizedBox(height: 8),
          FilledButton.icon(onPressed: _hire, icon: const Icon(Icons.person_add), label: Text(t.hire)),
          if (interviews.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(t.interview, style: Theme.of(context).textTheme.titleMedium),
            for (final iv in interviews)
              Card(child: ListTile(
                title: Text('${iv['scheduled_at'] ?? '-'}  (${iv['mode'] ?? ''})'),
                subtitle: Text('${iv['notes'] ?? ''}'),
                trailing: Chip(label: Text('${iv['status']}')),
              )),
          ],
          if (evaluations.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(t.evaluate, style: Theme.of(context).textTheme.titleMedium),
            for (final ev in evaluations)
              Card(child: ListTile(
                leading: CircleAvatar(child: Text('${ev['score'] ?? '-'}', style: const TextStyle(fontSize: 12))),
                title: Text('${t.recommendation}: ${ev['recommendation'] ?? '-'}'),
                subtitle: Text('${ev['notes'] ?? ''}'),
              )),
          ],
        ],
      ),
    );
  }

  Widget _row(String label, dynamic value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(children: [
      Expanded(flex: 2, child: Text(label, style: const TextStyle(fontWeight: FontWeight.w500))),
      Expanded(flex: 3, child: Text('${value ?? '-'}')),
    ]),
  );
}
