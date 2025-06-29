import 'package:ming_status_cli/ming_status_cli.dart';
import 'package:test/test.dart';

void main() {
  group('MingStatusCliApp', () {
    test('should create app instance', () {
      final app = MingStatusCliApp();
      expect(app, isNotNull);
      expect(app.availableCommands, isNotEmpty);
    });

    test('should contain basic commands', () {
      final app = MingStatusCliApp();
      final commands = app.availableCommands;

      expect(commands, contains('init'));
      expect(commands, contains('help')); // 内置的help命令
      expect(commands, contains('version'));
    });
  });
}
