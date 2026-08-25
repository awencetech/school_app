// Platform-aware file picker helper.
// Uses conditional imports to pick files on web via File input and FileReader,
// and delegates to FilePicker on mobile/desktop.

export 'file_picker_helper_web.dart' if (dart.library.io) 'file_picker_helper_io.dart';
