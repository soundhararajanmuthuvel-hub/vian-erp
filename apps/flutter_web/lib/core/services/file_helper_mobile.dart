import 'package:file_picker/file_picker.dart';
import 'dart:io' as io;

void saveFile(List<int> bytes, String fileName) {
  print('Saving file on native: $fileName');
}

void openUrl(String url) {
  print('Opening URL on native: $url');
}

class PickedFileResult {
  final String name;
  final List<int> bytes;
  PickedFileResult(this.name, this.bytes);
}

Future<PickedFileResult?> pickDrawingFile() async {
  try {
    final result = await FilePicker.pickFiles(
      type: FileType.any,
    );
    if (result != null && result.files.isNotEmpty) {
      final file = result.files.first;
      final bytes = file.bytes ?? io.File(file.path!).readAsBytesSync();
      return PickedFileResult(file.name, bytes);
    }
  } catch (e) {
    print('Error picking file: $e');
  }
  return null;
}
