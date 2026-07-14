import 'package:pharos_ai_runtime/core/config.dart';
import 'package:test/test.dart';

void main() {
  test('Config exposes default values', () {
    const config = Config();

    expect(config.appName, 'Pharos AI Runtime');
    expect(config.version, '0.1.0');
    expect(config.environment, 'development');
    expect(config.logLevel, 'info');
  });

  test('Config accepts overrides', () {
    const config = Config(
      appName: 'Custom App',
      version: '2.0.0',
      environment: 'production',
      logLevel: 'warn',
    );

    expect(config.appName, 'Custom App');
    expect(config.version, '2.0.0');
    expect(config.environment, 'production');
    expect(config.logLevel, 'warn');
  });
}
