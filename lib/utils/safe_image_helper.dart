import 'dart:convert';
import 'dart:typed_data';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

/// Centralized safe image helper that validates image sources and prevents
/// runtime exceptions (FormatException, ArgumentError, UriException) during
/// widget builds.
class SafeImageHelper {
  SafeImageHelper._();

  /// Validates whether [url] is a valid HTTP or HTTPS URL with a non-empty host.
  static bool isValidHttpUrl(String? url) {
    if (url == null) return false;
    final trimmed = url.trim();
    if (trimmed.isEmpty) return false;
    final uri = Uri.tryParse(trimmed);
    return uri != null &&
        uri.hasScheme &&
        (uri.scheme == 'http' || uri.scheme == 'https') &&
        uri.host.isNotEmpty;
  }

  /// Checks if [path] looks like a bundled Flutter asset.
  static bool isAssetPath(String? path) {
    if (path == null) return false;
    final trimmed = path.trim();
    return trimmed.startsWith('assets/');
  }

  /// Safely decodes a base64 string or data URI into bytes.
  ///
  /// Returns `null` if the input is null, empty, malformed, or not valid base64,
  /// without throwing any exceptions.
  static Uint8List? safeBase64Decode(String? source) {
    if (source == null) return null;
    var trimmed = source.trim();
    if (trimmed.isEmpty) return null;

    // Do not attempt to base64-decode obvious URLs or asset paths
    if (isValidHttpUrl(trimmed) || isAssetPath(trimmed)) {
      return null;
    }

    // Strip data URI scheme if present (e.g., "data:image/png;base64,")
    if (trimmed.toLowerCase().startsWith('data:')) {
      final commaIndex = trimmed.indexOf(',');
      if (commaIndex != -1) {
        trimmed = trimmed.substring(commaIndex + 1);
      } else {
        return null;
      }
    }

    // Remove any whitespace, newlines, or carriage returns
    var cleaned = trimmed.replaceAll(RegExp(r'\s+'), '');
    if (cleaned.isEmpty) return null;

    // Pad with '=' if length is not a multiple of 4
    final remainder = cleaned.length % 4;
    if (remainder != 0) {
      cleaned = cleaned.padRight(cleaned.length + (4 - remainder), '=');
    }

    try {
      final bytes = base64Decode(cleaned);
      return bytes.isNotEmpty ? bytes : null;
    } catch (_) {
      return null;
    }
  }

  /// Returns an [ImageProvider] for [source] if valid, or [fallback] if not.
  static ImageProvider? safeImageProvider(
    String? source, {
    ImageProvider? fallback,
  }) {
    if (source == null) return fallback;
    final trimmed = source.trim();
    if (trimmed.isEmpty) return fallback;

    if (isValidHttpUrl(trimmed)) {
      return CachedNetworkImageProvider(trimmed);
    }

    if (isAssetPath(trimmed)) {
      return AssetImage(trimmed);
    }

    final bytes = safeBase64Decode(trimmed);
    if (bytes != null) {
      return MemoryImage(bytes);
    }

    return fallback;
  }

  /// Builds a safe [Widget] rendering the image [source], gracefully falling back
  /// to [fallback] on any failure or invalid data.
  static Widget buildImage({
    required String? source,
    BoxFit fit = BoxFit.cover,
    double? width,
    double? height,
    Alignment alignment = Alignment.center,
    required Widget fallback,
  }) {
    if (source == null) return fallback;
    final trimmed = source.trim();
    if (trimmed.isEmpty) return fallback;

    if (isValidHttpUrl(trimmed)) {
      return CachedNetworkImage(
        imageUrl: trimmed,
        fit: fit,
        width: width,
        height: height,
        alignment: alignment,
        placeholder: (context, url) => fallback,
        errorWidget: (context, url, error) => fallback,
      );
    }

    if (isAssetPath(trimmed)) {
      return Image.asset(
        trimmed,
        fit: fit,
        width: width,
        height: height,
        alignment: alignment,
        errorBuilder: (context, error, stackTrace) => fallback,
      );
    }

    final bytes = safeBase64Decode(trimmed);
    if (bytes != null) {
      return Image.memory(
        bytes,
        fit: fit,
        width: width,
        height: height,
        alignment: alignment,
        errorBuilder: (context, error, stackTrace) => fallback,
      );
    }

    return fallback;
  }
}
