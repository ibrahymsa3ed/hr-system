String fmtDate(dynamic raw) {
  if (raw == null) return '-';
  final s = raw.toString();
  if (s.contains('T')) return s.split('T').first;
  return s.length >= 10 ? s.substring(0, 10) : s;
}

String fmtTime(dynamic raw) {
  if (raw == null) return '-';
  final s = raw.toString();
  if (s.contains('T') && s.length > 16) return s.substring(11, 16);
  return s;
}

String fmtDateTime(dynamic raw) {
  if (raw == null) return '-';
  final s = raw.toString();
  if (s.contains('T') && s.length > 16) return '${s.split('T').first} ${s.substring(11, 16)}';
  return s;
}
