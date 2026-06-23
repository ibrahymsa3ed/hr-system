import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../core/api_client.dart';
import '../../core/auth_service.dart';
import '../../l10n/app_localizations.dart';

class EmployeeFormScreen extends StatefulWidget {
  const EmployeeFormScreen({super.key, this.employee});
  final Map<String, dynamic>? employee;

  @override
  State<EmployeeFormScreen> createState() => _EmployeeFormScreenState();
}

class _EmployeeFormScreenState extends State<EmployeeFormScreen> {
  final _form = GlobalKey<FormState>();
  late final Map<String, TextEditingController> _c;
  XFile? _photo;
  bool _busy = false;
  bool _hasMobile = true;
  bool _medIns = false;
  bool _socIns = false;
  String _gender = 'male';
  String _status = 'active';
  int? _branchId;
  int? _sectionId;
  List<dynamic> _branches = [];
  List<dynamic> _sections = [];

  bool get isEdit => widget.employee != null;

  @override
  void initState() {
    super.initState();
    final e = widget.employee;
    _c = {
      for (final k in ['first_name', 'last_name', 'first_name_ar', 'last_name_ar', 'sub_code', 'phone', 'email', 'national_id', 'date_of_birth', 'hire_date', 'marital_status', 'basic_salary', 'medical_insurance_no', 'social_insurance_no', 'username', 'password'])
        k: TextEditingController(text: '${e?[k] ?? ''}'),
    };
    if (e != null) {
      _branchId = e['branch_id'] as int?;
      _sectionId = e['section_id'] as int?;
      _hasMobile = e['has_mobile'] == true;
      _medIns = e['medical_insurance'] == true;
      _socIns = e['social_insurance'] == true;
      _gender = e['gender'] ?? 'male';
      _status = e['employment_status'] ?? 'active';
    }
    _loadDropdowns();
  }

  Future<void> _loadDropdowns() async {
    final api = context.read<AuthService>().api;
    try {
      final b = await api.get('/branches');
      final s = await api.get('/sections');
      setState(() {
        _branches = b.data is List ? b.data : [];
        _sections = s.data is List ? s.data : [];
      });
    } catch (_) {}
  }

  Future<void> _pickPhoto() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery, maxWidth: 800, maxHeight: 800, imageQuality: 80);
    if (picked != null) setState(() => _photo = picked);
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _busy = true);
    try {
      final data = FormData.fromMap({
        for (final e in _c.entries)
          if (e.value.text.trim().isNotEmpty) e.key: e.value.text.trim(),
        'branch_id': _branchId,
        'section_id': _sectionId,
        'has_mobile': _hasMobile ? '1' : '0',
        'medical_insurance': _medIns ? '1' : '0',
        'social_insurance': _socIns ? '1' : '0',
        'gender': _gender,
        'employment_status': _status,
        if (_photo != null)
          'photo': kIsWeb
              ? MultipartFile.fromBytes(await _photo!.readAsBytes(), filename: _photo!.name)
              : await MultipartFile.fromFile(_photo!.path, filename: _photo!.name),
      });

      final api = context.read<AuthService>().api;
      if (isEdit) {
        data.fields.add(MapEntry('_method', 'PUT'));
        await api.post('/employees/${widget.employee!['id']}', data: data);
        if (mounted) Navigator.pop(context, true);
      } else {
        final res = await api.post('/employees', data: data);
        final creds = res.data is Map ? res.data['generated_credentials'] : null;
        if (mounted && creds != null) {
          final t = AppLocalizations.of(context)!;
          await showDialog(
            context: context,
            builder: (_) => AlertDialog(
              title: Text(t.credentialsCreated),
              content: SelectableText(
                t.credentialsInfo(creds['username'] ?? '', creds['password'] ?? ''),
              ),
              actions: [TextButton(onPressed: () => Navigator.pop(context), child: Text(t.save))],
            ),
          );
        }
        if (mounted) Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ApiClient.errorMessage(e))));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(isEdit ? t.editEmployee : t.addEmployee)),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Center(
              child: GestureDetector(
                onTap: _pickPhoto,
                child: CircleAvatar(
                  radius: 50,
                  backgroundImage: _photo != null && !kIsWeb ? FileImage(File(_photo!.path)) : null,
                  child: _photo == null ? const Icon(Icons.camera_alt, size: 32) : null,
                ),
              ),
            ),
            const SizedBox(height: 16),
            _field(t.firstName, 'first_name', required: true),
            _field(t.lastName, 'last_name', required: true),
            _field(t.firstNameAr, 'first_name_ar'),
            _field(t.lastNameAr, 'last_name_ar'),
            _field(t.subCode, 'sub_code', required: !isEdit),
            DropdownButtonFormField<int>(
              decoration: InputDecoration(labelText: t.branch, border: const OutlineInputBorder()),
              value: _branchId,
              items: _branches.map<DropdownMenuItem<int>>((b) => DropdownMenuItem(value: (b as Map)['id'] as int, child: Text('${b['name']}'))).toList(),
              onChanged: (v) => setState(() => _branchId = v),
              validator: isEdit ? null : (v) => v == null ? t.selectBranch : null,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<int>(
              decoration: InputDecoration(labelText: t.section, border: const OutlineInputBorder()),
              value: _sectionId,
              items: _sections.map<DropdownMenuItem<int>>((s) => DropdownMenuItem(value: (s as Map)['id'] as int, child: Text('${s['main_code']} - ${s['name']}'))).toList(),
              onChanged: (v) => setState(() => _sectionId = v),
              validator: isEdit ? null : (v) => v == null ? t.selectSection : null,
            ),
            const SizedBox(height: 12),
            if (!isEdit) ...[
              const Divider(height: 32),
              Text(t.loginCredentials, style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 8),
              _field(t.username, 'username'),
              _field(t.password, 'password'),
              const Divider(height: 32),
            ],
            _field(t.phone, 'phone'),
            _field(t.email, 'email', keyboard: TextInputType.emailAddress),
            _field(t.nationalId, 'national_id'),
            _field(t.dateOfBirth, 'date_of_birth'),
            _field(t.hireDate, 'hire_date'),
            _field(t.maritalStatus, 'marital_status'),
            _field(t.basicSalary, 'basic_salary', keyboard: TextInputType.number),
            DropdownButtonFormField<String>(
              decoration: InputDecoration(labelText: t.gender, border: const OutlineInputBorder()),
              value: _gender,
              items: [DropdownMenuItem(value: 'male', child: Text(t.male)), DropdownMenuItem(value: 'female', child: Text(t.female))],
              onChanged: (v) => setState(() => _gender = v ?? 'male'),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              decoration: InputDecoration(labelText: t.employmentStatus, border: const OutlineInputBorder()),
              value: _status,
              items: [
                DropdownMenuItem(value: 'active', child: Text(t.active)),
                DropdownMenuItem(value: 'suspended', child: Text(t.suspended)),
                DropdownMenuItem(value: 'resigned', child: Text(t.resigned)),
                DropdownMenuItem(value: 'terminated', child: Text(t.terminated)),
              ],
              onChanged: (v) => setState(() => _status = v ?? 'active'),
            ),
            const SizedBox(height: 12),
            SwitchListTile(title: Text(t.hasMobile), value: _hasMobile, onChanged: (v) => setState(() => _hasMobile = v)),
            SwitchListTile(title: Text(t.medicalInsurance), value: _medIns, onChanged: (v) => setState(() => _medIns = v)),
            _field(t.insuranceNo, 'medical_insurance_no'),
            SwitchListTile(title: Text(t.socialInsurance), value: _socIns, onChanged: (v) => setState(() => _socIns = v)),
            _field(t.insuranceNo, 'social_insurance_no'),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _busy ? null : _save,
              child: _busy ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2)) : Text(t.save),
            ),
          ],
        ),
      ),
    );
  }

  Widget _field(String label, String key, {bool required = false, TextInputType? keyboard}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: _c[key],
        decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
        keyboardType: keyboard,
        validator: required ? (v) => (v == null || v.trim().isEmpty) ? label : null : null,
      ),
    );
  }
}
