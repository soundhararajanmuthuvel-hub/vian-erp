void saveFile(List<int> bytes, String fileName) {
  throw UnsupportedError('Cannot save file without platform implementation');
}
void openUrl(String url) {
  throw UnsupportedError('Cannot open URL without platform implementation');
}

class PickedFileResult {
  final String name;
  final List<int> bytes;
  PickedFileResult(this.name, this.bytes);
}

Future<PickedFileResult?> pickDrawingFile() async {
  throw UnsupportedError('Cannot pick file without platform implementation');
}
