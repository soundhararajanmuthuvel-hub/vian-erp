import 'dart:html' as html;
import 'dart:async';

void saveFile(List<int> bytes, String fileName) {
  final blob = html.Blob([bytes]);
  final url = html.Url.createObjectUrlFromBlob(blob);
  final anchor = html.AnchorElement(href: url)
    ..setAttribute("download", fileName)
    ..click();
  html.Url.revokeObjectUrl(url);
}

void openUrl(String url) {
  html.window.open(url, '_blank');
}

class PickedFileResult {
  final String name;
  final List<int> bytes;
  PickedFileResult(this.name, this.bytes);
}

Future<PickedFileResult?> pickDrawingFile() async {
  final completer = Completer<PickedFileResult?>();
  final html.FileUploadInputElement uploadInput = html.FileUploadInputElement();
  uploadInput.accept = '.pdf,.png,.jpg,.jpeg';
  uploadInput.click();

  uploadInput.onChange.listen((e) async {
    final files = uploadInput.files;
    if (files == null || files.isEmpty) {
      completer.complete(null);
      return;
    }

    final file = files[0];
    final reader = html.FileReader();
    reader.readAsArrayBuffer(file);
    
    reader.onLoadEnd.listen((e) {
      final bytes = reader.result as List<int>;
      completer.complete(PickedFileResult(file.name, bytes));
    });
    
    reader.onError.listen((e) {
      completer.complete(null);
    });
  });

  return completer.future;
}
