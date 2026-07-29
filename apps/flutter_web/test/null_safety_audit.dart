import 'dart:io';

void main() {
  final dir = Directory('lib');
  final regex = RegExp(r'([a-zA-Z0-9_\)\]])!');

  print("File | Line | Expression | Can Become Null?");
  print("---|---|---|---");

  int total = 0;
  dir.listSync(recursive: true).forEach((entity) {
    if (entity is File && entity.path.endsWith('.dart')) {
      final lines = entity.readAsLinesSync();
      for (int i = 0; i < lines.length; i++) {
        final line = lines[i];
        final matches = regex.allMatches(line);
        if (matches.isNotEmpty) {
          for (final _ in matches) {
            total++;
            print(
              "${entity.path.replaceAll('\\', '/')} | ${i + 1} | `$line` | Yes/No",
            );
          }
        }
      }
    }
  });
  print("\nTotal Null Assertions Found: $total");
}
