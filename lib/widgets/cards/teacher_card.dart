import 'package:flutter/material.dart';

import 'profile_card.dart';

/// Teacher card (wrapper over ProfileCard) for future staff lists.
class TeacherCard extends StatelessWidget {
  const TeacherCard({
    super.key,
    required this.name,
    required this.position,
    required this.description,
    this.imageUrl,
  });

  final String name;
  final String position;
  final String description;
  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    return ProfileCard(
      name: name,
      position: position,
      description: description,
      imageUrl: imageUrl,
    );
  }
}

