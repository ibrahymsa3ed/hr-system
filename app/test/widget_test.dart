import 'package:flutter_test/flutter_test.dart';
import 'package:hr_app/core/locale_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({});

  test('LocaleProvider toggles between English and Arabic', () async {
    final provider = LocaleProvider();
    expect(provider.locale.languageCode, 'en');
    await provider.toggle();
    expect(provider.locale.languageCode, 'ar');
  });
}
