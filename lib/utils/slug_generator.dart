// Utility functions for generating slugs and IDs from group names.

/// Generates a URL-safe slug from a group name.
/// 
/// Rules:
/// - Trim whitespace
/// - Replace spaces with underscores
/// - Preserve hyphens
/// - Remove unsupported special characters
/// - Prevent duplicate underscores
/// 
/// Examples:
/// NCC2022 => NCC2022
/// USS - NSS G11 => USS-NSS_G11
/// JRC - GRADE 6_TO_9 => JRC-GRADE_6_TO_9
String generateGroupSlug(String name) {
  if (name.isEmpty) return '';
  
  // Trim whitespace
  String slug = name.trim();
  
  // Replace multiple spaces with single space
  slug = slug.replaceAll(RegExp(r'\s+'), ' ');
  
  // Handle specific cases: " - " becomes "-"
  slug = slug.replaceAll(' - ', '-');
  
  // Replace remaining spaces with underscores
  slug = slug.replaceAll(' ', '_');
  
  // Remove any remaining unsupported special characters (keep alphanumeric, hyphens, underscores)
  slug = slug.replaceAll(RegExp(r'[^a-zA-Z0-9\-_]'), '');
  
  // Remove consecutive underscores
  slug = slug.replaceAll(RegExp(r'_+'), '_');
  
  // Remove leading/trailing underscores or hyphens
  slug = slug.replaceAll(RegExp(r'^[_\-]+|[_\-]+$'), '');
  
  return slug;
}

/// Generates a page ID for group navigation.
/// Format: mmhs-2022-{GROUP_SLUG}
/// 
/// Example:
/// NCC2022 => mmhs-2022-NCC2022
/// USS - NSS G11 => mmhs-2022-USS-NSS_G11
String generateGroupPageId(String groupName) {
  final slug = generateGroupSlug(groupName);
  return 'mmhs-2022-$slug';
}

/// Generates a database ID for group identification.
/// Format: SAMUNI-2022-{GROUP_SLUG}
/// 
/// Example:
/// NCC2022 => SAMUNI-2022-NCC2022
/// USS - NSS G11 => SAMUNI-2022-USS-NSS_G11
String generateGroupDatabaseId(String groupName) {
  final slug = generateGroupSlug(groupName);
  return 'SAMUNI-2022-$slug';
}
