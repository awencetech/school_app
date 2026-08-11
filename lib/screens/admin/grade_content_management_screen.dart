import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:provider/provider.dart';

import '../../models/sports_achievement_entry.dart';
import '../../models/topper_entry.dart';
import '../../services/school_config_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/admin_bottom_nav.dart';
import '../../routes/app_routes.dart';

class GradeContentManagementScreen extends StatefulWidget {
  const GradeContentManagementScreen({super.key});

  @override
  State<GradeContentManagementScreen> createState() => _GradeContentManagementScreenState();
}

class _GradeContentManagementScreenState extends State<GradeContentManagementScreen> {
  late final SchoolConfigService _config;
  List<TopperEntry> _gradeX = [];
  List<TopperEntry> _gradeXII = [];
  List<SportsAchievementEntry> _sportsAchievements = [];

  @override
  void initState() {
    super.initState();
    _config = context.read<SchoolConfigService>();
    _loadSavedData();
  }

  void _loadSavedData() {
    setState(() {
      _gradeX = List<TopperEntry>.from(_config.gradeXTopper);
      _gradeXII = List<TopperEntry>.from(_config.gradeXIITopper);
      _sportsAchievements = List<SportsAchievementEntry>.from(_config.sportsAchievements);
    });
  }

  Future<String?> _pickImage() async {
    final result = await FilePicker.pickFiles(withData: true, type: FileType.image);
    if (result == null || result.files.isEmpty) return null;

    final file = result.files.first;
    final bytes = file.bytes;
    if (bytes == null) return null;

    if (bytes.lengthInBytes > 5 * 1024 * 1024) {
      if (!mounted) return null;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Image must be 5MB or less.')),
      );
      return null;
    }

    return base64Encode(bytes);
  }

  Future<String?> _cropImage(String base64Image) async {
    if (kIsWeb) {
      if (!mounted) return null;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Crop is not available on web.')),
      );
      return null;
    }

    final bytes = base64Decode(base64Image);
    final tempDir = Directory.systemTemp;
    final tempFile = File('${tempDir.path}${Platform.pathSeparator}grade_crop_${DateTime.now().millisecondsSinceEpoch}.png');
    await tempFile.writeAsBytes(bytes);

    final cropped = await ImageCropper().cropImage(
      sourcePath: tempFile.path,
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: 'Crop Image',
          aspectRatioPresets: [
            CropAspectRatioPreset.square,
            CropAspectRatioPreset.ratio4x3,
            CropAspectRatioPreset.original,
          ],
        ),
        IOSUiSettings(
          title: 'Crop Image',
          aspectRatioPresets: [
            CropAspectRatioPreset.square,
            CropAspectRatioPreset.ratio4x3,
            CropAspectRatioPreset.original,
          ],
        ),
      ],
    );

    if (cropped == null) return null;

    final croppedBytes = await cropped.readAsBytes();
    await tempFile.delete();
    return base64Encode(croppedBytes);
  }

  Future<void> _showTopperDialog({TopperEntry? entry, required bool isGradeX, int? index}) async {
    final nameController = TextEditingController(text: entry?.studentName ?? '');
    final marksController = TextEditingController(text: entry?.marks ?? '');
    String? photoBase64 = entry?.photoBase64;
    String selectedFit = entry?.imageFit ?? 'cover';
    Map<String, dynamic>? cropData = entry?.cropData;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            return AlertDialog(
              title: Text(entry == null ? 'Add Student' : 'Edit Student', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
              content: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextButton.icon(
                      onPressed: () async {
                        final result = await _pickImage();
                        if (result != null) {
                          setDialogState(() {
                            photoBase64 = result;
                            cropData = null;
                            selectedFit = 'cover';
                          });
                        }
                      },
                      icon: const Icon(Icons.upload_file),
                      label: Text(photoBase64 == null ? 'Upload Photo' : 'Change Image', style: GoogleFonts.poppins()),
                    ),
                    const SizedBox(height: 12),
                    if (photoBase64 != null) ...[
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          OutlinedButton.icon(
                            onPressed: () => _showImagePreview(photoBase64!),
                            icon: const Icon(Icons.visibility),
                            label: Text('Preview', style: GoogleFonts.poppins()),
                          ),
                          OutlinedButton.icon(
                            onPressed: () async {
                              final cropped = await _cropImage(photoBase64!);
                              if (cropped != null) {
                                setDialogState(() {
                                  photoBase64 = cropped;
                                  cropData = {'cropped': true};
                                });
                              }
                            },
                            icon: const Icon(Icons.crop),
                            label: Text('Crop Image', style: GoogleFonts.poppins()),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      AspectRatio(
                        aspectRatio: 4 / 5,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: _buildImageFromString(photoBase64!, fit: _boxFitForString(selectedFit)),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text('Image Fit', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: [
                          _buildFitChip('cover', 'Cover', selectedFit == 'cover', setDialogState, () {
                            setDialogState(() => selectedFit = 'cover');
                          }),
                          _buildFitChip('contain', 'Contain', selectedFit == 'contain', setDialogState, () {
                            setDialogState(() => selectedFit = 'contain');
                          }),
                          _buildFitChip('fill', 'Fill', selectedFit == 'fill', setDialogState, () {
                            setDialogState(() => selectedFit = 'fill');
                          }),
                        ],
                      ),
                    ] else ...[
                      Container(
                        height: 120,
                        decoration: BoxDecoration(
                          color: AppColors.divider,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Text('No photo selected', style: GoogleFonts.poppins(color: AppColors.hintText)),
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    TextField(
                      controller: nameController,
                      decoration: InputDecoration(labelText: 'Student Name', border: const OutlineInputBorder()),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: marksController,
                      decoration: InputDecoration(labelText: 'Marks / Total Marks', border: const OutlineInputBorder()),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: Text('Cancel', style: GoogleFonts.poppins()),
                ),
                FilledButton(
                  onPressed: () {
                    final studentName = nameController.text.trim();
                    final marks = marksController.text.trim();
                    if (photoBase64 == null || studentName.isEmpty || marks.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Photo, name, and marks are required.')),
                      );
                      return;
                    }

                    final newEntry = TopperEntry(
                      photoBase64: photoBase64!,
                      studentName: studentName,
                      marks: marks,
                      imageFit: selectedFit,
                      cropData: cropData,
                    );

                    setState(() {
                      final target = isGradeX ? _gradeX : _gradeXII;
                      if (index != null) {
                        target[index] = newEntry;
                      } else {
                        target.add(newEntry);
                      }
                    });

                    Navigator.of(dialogContext).pop();
                  },
                  child: Text('Save', style: GoogleFonts.poppins(color: AppColors.white)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _showAchievementSheet({SportsAchievementEntry? entry, int? index}) async {
    final studentController = TextEditingController(text: entry?.studentName ?? '');
    final descriptionController = TextEditingController(text: entry?.description ?? '');
    String? imageBase64 = entry?.imageBase64;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (sheetContext, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(bottom: MediaQuery.of(sheetContext).viewInsets.bottom),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      entry == null ? 'Add Achievement' : 'Edit Achievement',
                      style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 16),
                    TextButton.icon(
                      onPressed: () async {
                        final result = await _pickImage();
                        if (result != null) {
                          setSheetState(() {
                            imageBase64 = result;
                          });
                        }
                      },
                      icon: const Icon(Icons.upload_file),
                      label: Text(imageBase64 == null ? 'Upload Image' : 'Replace Image', style: GoogleFonts.poppins()),
                    ),
                    const SizedBox(height: 12),
                    if (imageBase64 != null)
                      AspectRatio(
                        aspectRatio: 1,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: _buildImageFromString(imageBase64!),
                        ),
                      )
                    else
                      Container(
                        height: 120,
                        decoration: BoxDecoration(
                          color: AppColors.divider,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Text('No achievement image', style: GoogleFonts.poppins(color: AppColors.hintText)),
                        ),
                      ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: studentController,
                      decoration: InputDecoration(labelText: 'Student Name', border: const OutlineInputBorder()),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: descriptionController,
                      minLines: 3,
                      maxLines: 5,
                      decoration: InputDecoration(labelText: 'Achievement Description', border: const OutlineInputBorder()),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.of(sheetContext).pop(),
                            child: Text('Cancel', style: GoogleFonts.poppins()),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: FilledButton(
                            onPressed: () {
                              final studentName = studentController.text.trim();
                              final description = descriptionController.text.trim();
                              if (imageBase64 == null || studentName.isEmpty || description.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Image, student name, and description are required.')),
                                );
                                return;
                              }

                              final updatedEntry = SportsAchievementEntry(
                                imageBase64: imageBase64!,
                                studentName: studentName,
                                achievementTitle: '',
                                description: description,
                              );

                              setState(() {
                                if (index == null) {
                                  _sportsAchievements.add(updatedEntry);
                                } else {
                                  _sportsAchievements[index] = updatedEntry;
                                }
                              });

                              Navigator.of(sheetContext).pop();
                            },
                            child: Text('Save', style: GoogleFonts.poppins(color: AppColors.white)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _deleteAchievement(int index) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text('Delete Achievement?', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text('Cancel', style: GoogleFonts.poppins()),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text('Delete', style: GoogleFonts.poppins(color: AppColors.white)),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      setState(() {
        _sportsAchievements.removeAt(index);
      });
    }
  }

  Future<void> _saveChanges() async {
    if (_gradeX.length > 3 || _gradeXII.length > 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Each grade can have a maximum of 3 students.')),
      );
      return;
    }

    for (final student in [..._gradeX, ..._gradeXII]) {
      if (student.photoBase64.isEmpty || student.studentName.isEmpty || student.marks.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Each topper requires a photo, name, and marks.')),
        );
        return;
      }
    }

    for (final achievement in _sportsAchievements) {
      if (achievement.imageBase64.isEmpty || achievement.studentName.isEmpty || achievement.description.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Each achievement requires an image, student name, and description.')),
        );
        return;
      }
    }

    final saved = await _config.save(
      gradeXTopper: _gradeX,
      gradeXIITopper: _gradeXII,
      sportsAchievements: _sportsAchievements,
    );

    if (!mounted) return;
    if (saved) {
      _loadSavedData();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Grade Page Updated Successfully')),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Unable to save grade page. Please try again.')),
    );
  }

  Widget _buildImageFromString(String imageData, {BoxFit fit = BoxFit.contain}) {
    final trimmed = imageData.trim();
    if (trimmed.isEmpty) {
      return Container(
        color: AppColors.divider,
        child: const Center(child: Icon(Icons.image_outlined, color: AppColors.hintText)),
      );
    }

    final uri = Uri.tryParse(trimmed);
    if (uri != null && uri.hasScheme && (uri.scheme == 'http' || uri.scheme == 'https')) {
      return Image.network(
        trimmed,
        fit: fit,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            color: AppColors.divider,
            child: const Center(child: Icon(Icons.image_outlined, color: AppColors.hintText)),
          );
        },
      );
    }

    UriData? uriData;
    try {
      uriData = UriData.parse(trimmed);
    } catch (_) {
      uriData = null;
    }
    if (uriData != null && uriData.contentAsBytes().isNotEmpty) {
      return Image.memory(uriData.contentAsBytes(), fit: fit);
    }

    final normalized = trimmed.toLowerCase().startsWith('data:')
        ? trimmed.substring(trimmed.indexOf(',') + 1).replaceAll(RegExp(r'\s+'), '')
        : trimmed.replaceAll(RegExp(r'\s+'), '');

    try {
      final bytes = base64Decode(normalized);
      return Image.memory(bytes, fit: fit);
    } catch (_) {
      return Container(
        color: AppColors.divider,
        child: const Center(child: Icon(Icons.image_outlined, color: AppColors.hintText)),
      );
    }
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w700),
    );
  }

  BoxFit _boxFitForString(String imageFit) {
    switch (imageFit) {
      case 'contain':
        return BoxFit.contain;
      case 'fill':
        return BoxFit.fill;
      case 'cover':
      default:
        return BoxFit.cover;
    }
  }

  Future<void> _showImagePreview(String imageData) async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppBar(
                backgroundColor: AppColors.topBar,
                automaticallyImplyLeading: false,
                title: Text('Image Preview', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600)),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(dialogContext).pop(),
                  ),
                ],
              ),
              AspectRatio(
                aspectRatio: 4 / 5,
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
                  child: _buildImageFromString(imageData, fit: BoxFit.cover),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFitChip(String value, String label, bool selected, void Function(void Function()) setDialogState, VoidCallback onTap) {
    return ChoiceChip(
      label: Text(label, style: GoogleFonts.poppins()),
      selected: selected,
      onSelected: (_) => onTap(),
    );
  }

  Widget _buildTopperCard(TopperEntry topper, int index, bool isGradeX) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AspectRatio(
              aspectRatio: 4 / 5,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: topper.photoBase64.isEmpty
                    ? Container(
                        color: AppColors.divider,
                        child: const Center(child: Icon(Icons.person, color: AppColors.hintText)),
                      )
                    : _buildImageFromString(topper.photoBase64, fit: BoxFit.cover),
              ),
            ),
            const SizedBox(height: 12),
            Text(topper.studentName, style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            Text(topper.marks, style: GoogleFonts.poppins(color: AppColors.hintText)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  onPressed: () => _showImagePreview(topper.photoBase64),
                  icon: const Icon(Icons.visibility, size: 18),
                  label: Text('Preview', style: GoogleFonts.poppins()),
                ),
                OutlinedButton.icon(
                  onPressed: () => _showTopperDialog(entry: topper, isGradeX: isGradeX, index: index),
                  icon: const Icon(Icons.edit, size: 18),
                  label: Text('Edit', style: GoogleFonts.poppins()),
                ),
                IconButton(
                  onPressed: () {
                    setState(() {
                      if (isGradeX) {
                        _gradeX.removeAt(index);
                      } else {
                        _gradeXII.removeAt(index);
                      }
                    });
                  },
                  icon: const Icon(Icons.delete_outline),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddStudentCard(String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 1,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AspectRatio(
                aspectRatio: 1,
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.divider,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFBDBDBD)),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.add, size: 32, color: AppColors.hintText),
                        const SizedBox(height: 8),
                        Text(
                          label,
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.hintText,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAchievementRow(SportsAchievementEntry entry, int index) {
    return Card(
      key: ValueKey(entry.hashCode ^ index),
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: entry.imageBase64.isEmpty
              ? Container(
                  width: 72,
                  height: 72,
                  color: AppColors.divider,
                  child: const Icon(Icons.image_outlined, color: AppColors.hintText),
                )
              : SizedBox(
                  width: 72,
                  height: 72,
                  child: _buildImageFromString(entry.imageBase64),
                ),
        ),
        title: Text(entry.studentName, style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
        subtitle: Text(entry.description, style: GoogleFonts.poppins(color: AppColors.hintText), maxLines: 3, overflow: TextOverflow.ellipsis),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => _showAchievementSheet(entry: entry, index: index),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: () => _deleteAchievement(index),
            ),
            const Icon(Icons.drag_handle),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.topBar,
        title: Text('Grade Content Management', style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
        leading: Navigator.canPop(context)
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.of(context).pop(),
              )
            : null,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildSectionTitle('Grade X Toppers'),
            const SizedBox(height: 12),
            LayoutBuilder(
              builder: (context, constraints) {
                final crossAxisCount = constraints.maxWidth > 720 ? 3 : 1;
                return Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    for (var i = 0; i < _gradeX.length; i++)
                      SizedBox(width: constraints.maxWidth / crossAxisCount - 12, child: _buildTopperCard(_gradeX[i], i, true)),
                    if (_gradeX.length < 3)
                      SizedBox(
                        width: constraints.maxWidth / crossAxisCount - 12,
                        child: _buildAddStudentCard('Add Student', () => _showTopperDialog(isGradeX: true)),
                      ),
                  ],
                );
              },
            ),
            const SizedBox(height: 24),
            _buildSectionTitle('Grade XII Toppers'),
            const SizedBox(height: 12),
            LayoutBuilder(
              builder: (context, constraints) {
                final crossAxisCount = constraints.maxWidth > 720 ? 3 : 1;
                return Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    for (var i = 0; i < _gradeXII.length; i++)
                      SizedBox(width: constraints.maxWidth / crossAxisCount - 12, child: _buildTopperCard(_gradeXII[i], i, false)),
                    if (_gradeXII.length < 3)
                      SizedBox(
                        width: constraints.maxWidth / crossAxisCount - 12,
                        child: _buildAddStudentCard('Add Student', () => _showTopperDialog(isGradeX: false)),
                      ),
                  ],
                );
              },
            ),
            const SizedBox(height: 24),
            _buildSectionTitle('Sports Achievements'),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: () => _showAchievementSheet(),
              icon: const Icon(Icons.add),
              label: Text('Add Achievement', style: GoogleFonts.poppins(color: AppColors.white)),
            ),
            const SizedBox(height: 12),
            ReorderableListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _sportsAchievements.length,
              onReorderItem: (oldIndex, newIndex) {
                setState(() {
                  if (newIndex > oldIndex) newIndex -= 1;
                  final item = _sportsAchievements.removeAt(oldIndex);
                  _sportsAchievements.insert(newIndex, item);
                });
              },
              itemBuilder: (context, index) {
                return _buildAchievementRow(_sportsAchievements[index], index);
              },
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: FilledButton(
                    onPressed: _saveChanges,
                    child: Text('Save Changes', style: GoogleFonts.poppins(color: AppColors.white)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    onPressed: _loadSavedData,
                    child: Text('Reset', style: GoogleFonts.poppins()),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      bottomNavigationBar: AdminBottomNavigationBar(
        currentIndex: 0,
        onItemSelected: (index) {
          switch (index) {
            case 0:
              Navigator.of(context).pushNamedAndRemoveUntil(
                AppRoutes.adminDashboard,
                (route) => false,
              );
              break;
            case 1:
              Navigator.of(context).pushNamed(AppRoutes.adminDashboard);
              break;
            case 2:
              Navigator.of(context).pushNamedAndRemoveUntil(
                AppRoutes.adminDashboard,
                (route) => false,
              );
              break;
            case 3:
              Navigator.of(context).pushNamed(AppRoutes.supportQuery);
              break;
            case 4:
              Navigator.of(context).pushNamedAndRemoveUntil(
                AppRoutes.main,
                (route) => false,
              );
              break;
          }
        },
      ),
    );
  }
}
