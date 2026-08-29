// Web implementation using dart:html to read the picked file as a data URL.
// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:async';
import 'dart:html' as html;

Future<String?> pickImageAsDataUri() async {
  final completer = Completer<String?>();
  final input = html.FileUploadInputElement();
  input.accept = 'image/*';
  input.multiple = false;
  input.click();

  input.onChange.listen((event) {
    final files = input.files;
    if (files == null || files.isEmpty) {
      completer.complete(null);
      return;
    }
    final file = files.first;
    final reader = html.FileReader();
    reader.onLoad.listen((_) {
      final result = reader.result;
      if (result is String) {
        completer.complete(result);
      } else {
        completer.complete(null);
      }
    });
    reader.onError.listen((_) => completer.complete(null));
    reader.readAsDataUrl(file);
  });

  return completer.future;
}
