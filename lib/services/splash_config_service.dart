import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../models/main_page_info.dart';
import 'main_page_info_repository.dart';
import 'preferences_service.dart';

class SplashConfigService extends ChangeNotifier {
  static const _imageKey = 'splash_image_base64';
  static const _titleKey = 'splash_title';
  static const _subtitleKey = 'splash_subtitle';
  static const _sinceKey = 'splash_since';
  static const _quoteKey = 'splash_quote';
  static const _imageScaleKey = 'splash_image_scale';
  static const _imageOffsetXKey = 'splash_image_offset_x';
  static const _imageOffsetYKey = 'splash_image_offset_y';

  final MainPageInfoRepository _repository = MainPageInfoRepository();

  String? imageBase64;
  String title = 'SCHOOL NAME';
  String subtitle = 'Motto goes here';
  String since = '1987';
  String quote = '';
  double imageScale = 1.0;
  double imageOffsetX = 0.0;
  double imageOffsetY = 0.0;

  SplashConfigService() {
    _load();
  }

  Future<void> _load() async {
    final img = await PreferencesService.getString(_imageKey);
    final t = await PreferencesService.getString(_titleKey);
    final s = await PreferencesService.getString(_subtitleKey);
    final y = await PreferencesService.getString(_sinceKey);
    final q = await PreferencesService.getString(_quoteKey);
    final scale = await PreferencesService.getString(_imageScaleKey);
    final offX = await PreferencesService.getString(_imageOffsetXKey);
    final offY = await PreferencesService.getString(_imageOffsetYKey);

    imageBase64 = img;
    if (t != null && t.isNotEmpty) title = t;
    if (s != null && s.isNotEmpty) subtitle = s;
    if (y != null && y.isNotEmpty) since = y;
    if (q != null && q.isNotEmpty) quote = q;
    if (scale != null && scale.isNotEmpty) imageScale = double.tryParse(scale) ?? imageScale;
    if (offX != null && offX.isNotEmpty) imageOffsetX = double.tryParse(offX) ?? imageOffsetX;
    if (offY != null && offY.isNotEmpty) imageOffsetY = double.tryParse(offY) ?? imageOffsetY;

    try {
      final saved = await _repository.getMainPageInfo();

      // Server authoritative: overwrite local splash values and persist
      title = saved.splashScreen.title ?? '';
      await PreferencesService.setString(_titleKey, title);

      subtitle = saved.splashScreen.subtitle ?? '';
      await PreferencesService.setString(_subtitleKey, subtitle);

      since = saved.splashScreen.sinceYear ?? '';
      await PreferencesService.setString(_sinceKey, since);

      quote = (saved.splashScreen.quote ?? '');
      await PreferencesService.setString(_quoteKey, quote);

      // image may be base64 or an HTTP/HTTPS URL - store as-is and let widgets choose how to render
      imageBase64 = saved.splashScreen.image ?? '';
      await PreferencesService.setString(_imageKey, imageBase64 ?? '');

      imageScale = saved.splashScreen.imageScale is double ? saved.splashScreen.imageScale : (double.tryParse(saved.splashScreen.imageScale?.toString() ?? '') ?? imageScale);
      await PreferencesService.setString(_imageScaleKey, imageScale.toString());

      imageOffsetX = saved.splashScreen.imageOffsetX is double ? saved.splashScreen.imageOffsetX : (double.tryParse(saved.splashScreen.imageOffsetX?.toString() ?? '') ?? imageOffsetX);
      await PreferencesService.setString(_imageOffsetXKey, imageOffsetX.toString());

      imageOffsetY = saved.splashScreen.imageOffsetY is double ? saved.splashScreen.imageOffsetY : (double.tryParse(saved.splashScreen.imageOffsetY?.toString() ?? '') ?? imageOffsetY);
      await PreferencesService.setString(_imageOffsetYKey, imageOffsetY.toString());
    } catch (_) {
      // Keep the cached values if the server is temporarily unavailable.
    }

    notifyListeners();
  }

  Future<bool> save({String? imageBase64, String? title, String? subtitle, String? since, String? quote, double? imageScale, double? imageOffsetX, double? imageOffsetY}) async {
    // Backend-first save: attempt to persist to server and only update local cache on success.
    try {
      // Build splash payload using current in-memory state overridden by arguments
      final newTitle = title ?? this.title;
      final newSubtitle = subtitle ?? this.subtitle;
      final newQuote = quote ?? this.quote;
      final newSince = since ?? this.since;
      var newImage = imageBase64 ?? this.imageBase64 ?? '';
      final newImageScale = imageScale ?? this.imageScale;
      final newImageOffsetX = imageOffsetX ?? this.imageOffsetX;
      final newImageOffsetY = imageOffsetY ?? this.imageOffsetY;

      // If image looks like base64 (not a URL), upload it first so DB stores a reachable URL.
      if (newImage.isNotEmpty && !newImage.startsWith('http')) {
        try {
          final bytes = base64Decode(newImage);
          final uploadedUrl = await _repository.uploadPoster(fileName: 'splash-${DateTime.now().millisecondsSinceEpoch}.png', bytes: bytes);
          newImage = uploadedUrl;
        } catch (e) {
          return false;
        }
      }

      final payload = {
        'title': newTitle,
        'subtitle': newSubtitle,
        'quote': newQuote,
        'image': newImage,
        'sinceYear': newSince,
        'imageScale': newImageScale,
        'imageOffsetX': newImageOffsetX,
        'imageOffsetY': newImageOffsetY,
        'enabled': true,
      };

      final updated = await _repository.updateSplashScreen(payload);

      // Update local state and preferences only after successful backend save
      if (updated.splashScreen.title.isNotEmpty) this.title = updated.splashScreen.title;
      if (updated.splashScreen.subtitle.isNotEmpty) this.subtitle = updated.splashScreen.subtitle;
      if ((updated.splashScreen.quote ?? '').isNotEmpty) this.quote = (updated.splashScreen.quote ?? '');
      if (updated.splashScreen.sinceYear.isNotEmpty) this.since = updated.splashScreen.sinceYear;
      if (updated.splashScreen.image.isNotEmpty) this.imageBase64 = updated.splashScreen.image;
      imageScale = updated.splashScreen.imageScale is double ? updated.splashScreen.imageScale : (double.tryParse(updated.splashScreen.imageScale?.toString() ?? '') ?? imageScale);
      imageOffsetX = updated.splashScreen.imageOffsetX is double ? updated.splashScreen.imageOffsetX : (double.tryParse(updated.splashScreen.imageOffsetX?.toString() ?? '') ?? imageOffsetX);
      imageOffsetY = updated.splashScreen.imageOffsetY is double ? updated.splashScreen.imageOffsetY : (double.tryParse(updated.splashScreen.imageOffsetY?.toString() ?? '') ?? imageOffsetY);

      // Persist to preferences as a cache for offline fallback
      await PreferencesService.setString(_imageKey, this.imageBase64 ?? '');
      await PreferencesService.setString(_titleKey, this.title);
      await PreferencesService.setString(_subtitleKey, this.subtitle);
      await PreferencesService.setString(_sinceKey, this.since);
      await PreferencesService.setString(_quoteKey, this.quote);
      await PreferencesService.setString(_imageScaleKey, newImageScale.toString());
      await PreferencesService.setString(_imageOffsetXKey, newImageOffsetX.toString());
      await PreferencesService.setString(_imageOffsetYKey, newImageOffsetY.toString());

      notifyListeners();
      return true;
    } catch (_) {
      // Do not overwrite local cache if backend save fails
      return false;
    }
  }
}
