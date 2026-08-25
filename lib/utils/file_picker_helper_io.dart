// IO implementation using package:file_picker for native platforms.
import 'dart:io';
import 'dart:async';
import 'dart:convert';

import 'package:file_picker/file_picker.dart';

Future<String?> pickImageAsDataUri() async {
  final result = await FilePicker.pickFiles(type: FileType.image);
  if (result == null) return null;
  // result may be List<PlatformFile> or PlatformFile or FilePickerResult
  dynamic file;
  if (result is List && result.isNotEmpty) file = result.first;
  else if (result is PlatformFile) file = result;
  else {
    try {
      final files = (result as dynamic).files;
      if (files is List && files.isNotEmpty) file = files.first;
    } catch (_) {}
  }
  if (file == null) return null;
  final path = file.path as String?;
  if (path != null && path.isNotEmpty) return path;
  final bytes = (file as dynamic).bytes as List<int>?;
  if (bytes == null) return null;
  final ext = (file as dynamic).extension as String? ?? 'png';
  final tmp = File('${Directory.systemTemp.path}/school_app_${DateTime.now().millisecondsSinceEpoch}.$ext');
  await tmp.writeAsBytes(bytes);
  return tmp.path;
}
