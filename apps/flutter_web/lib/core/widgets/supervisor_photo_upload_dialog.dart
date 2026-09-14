import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';
import '../theme/theme.dart';

/// Gold-standard 3-4 click photo upload dialog for Site Supervisors
class SupervisorPhotoUploadDialog extends StatefulWidget {
  final List<dynamic> projects;
  final int? initialProjectId;
  final VoidCallback? onUploaded;

  const SupervisorPhotoUploadDialog({
    super.key,
    required this.projects,
    this.initialProjectId,
    this.onUploaded,
  });

  @override
  State<SupervisorPhotoUploadDialog> createState() => _SupervisorPhotoUploadDialogState();
}

class _SupervisorPhotoUploadDialogState extends State<SupervisorPhotoUploadDialog> {
  int? _selectedProjectId;
  String _category = 'Foundation';
  final TextEditingController _notesController = TextEditingController();
  final List<PlatformFile> _selectedFiles = [];
  bool _isUploading = false;
  double _uploadProgress = 0.0;
  String? _errorMessage;
  bool _uploadSuccess = false;

  final List<String> _categories = [
    'Foundation',
    'Structure',
    'Brickwork',
    'Plumbing',
    'Electrical',
    'Plastering',
    'Flooring',
    'Painting',
    'Finishing',
    'Site Inspection',
    'Other'
  ];

  @override
  void initState() {
    super.initState();
    if (widget.initialProjectId != null) {
      _selectedProjectId = widget.initialProjectId;
    } else if (widget.projects.isNotEmpty) {
      _selectedProjectId = widget.projects.first['id'];
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickPhotos() async {
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.image,
        allowMultiple: true,
        withData: true,
      );

      if (result != null && result.files.isNotEmpty) {
        setState(() {
          _selectedFiles.addAll(result.files);
          _errorMessage = null;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to select photos: $e';
      });
    }
  }

  void _removePhoto(int index) {
    setState(() {
      _selectedFiles.removeAt(index);
    });
  }

  Future<void> _uploadPhotos() async {
    if (_selectedProjectId == null) {
      setState(() => _errorMessage = 'Please select a project');
      return;
    }

    if (_selectedFiles.isEmpty) {
      setState(() => _errorMessage = 'Please select at least one photo');
      return;
    }

    setState(() {
      _isUploading = true;
      _uploadProgress = 0.1;
      _errorMessage = null;
    });

    try {
      // Progress simulation for responsive UX
      for (double p = 0.2; p <= 0.8; p += 0.2) {
        await Future.delayed(const Duration(milliseconds: 150));
        if (mounted) setState(() => _uploadProgress = p);
      }

      final res = await ApiService.uploadProjectPhotos(
        _selectedProjectId!,
        files: _selectedFiles,
        category: _category,
        description: _notesController.text.trim().isNotEmpty ? _notesController.text.trim() : null,
      );

      if (res['success'] == true) {
        if (mounted) {
          setState(() {
            _uploadProgress = 1.0;
            _uploadSuccess = true;
            _isUploading = false;
          });
          widget.onUploaded?.call();
          await Future.delayed(const Duration(seconds: 1));
          if (mounted) Navigator.of(context).pop(true);
        }
      } else {
        if (mounted) {
          setState(() {
            _isUploading = false;
            _errorMessage = res['message'] ?? 'Failed to upload photos. Please try again.';
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isUploading = false;
          _errorMessage = 'Error during upload: $e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF18181B),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: VianTheme.primaryGold.withOpacity(0.3)),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Container(
        width: 600,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: VianTheme.primaryGold.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.add_a_photo_outlined, color: VianTheme.primaryGold, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'UPLOAD SITE PHOTOS',
                        style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                      Text(
                        'Direct camera/gallery upload for project timeline',
                        style: GoogleFonts.inter(color: Colors.white60, fontSize: 11),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white54, size: 20),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Success banner
            if (_uploadSuccess) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle, color: Colors.green, size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Photos uploaded successfully! Syncing gallery...',
                        style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Error banner
            if (_errorMessage != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.redAccent.withOpacity(0.5)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: Colors.redAccent, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: GoogleFonts.inter(color: Colors.redAccent, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Project Selector & Category
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: DropdownButtonFormField<int>(
                    value: _selectedProjectId,
                    dropdownColor: const Color(0xFF242427),
                    style: GoogleFonts.inter(color: Colors.white, fontSize: 13),
                    decoration: InputDecoration(
                      labelText: 'Project',
                      labelStyle: GoogleFonts.inter(color: Colors.white70, fontSize: 12),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Colors.white24),
                      ),
                    ),
                    items: widget.projects.map<DropdownMenuItem<int>>((p) {
                      return DropdownMenuItem<int>(
                        value: p['id'],
                        child: Text(p['name'] ?? 'Project #${p['id']}', overflow: TextOverflow.ellipsis),
                      );
                    }).toList(),
                    onChanged: _isUploading ? null : (val) => setState(() => _selectedProjectId = val),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: DropdownButtonFormField<String>(
                    value: _category,
                    dropdownColor: const Color(0xFF242427),
                    style: GoogleFonts.inter(color: Colors.white, fontSize: 13),
                    decoration: InputDecoration(
                      labelText: 'Category',
                      labelStyle: GoogleFonts.inter(color: Colors.white70, fontSize: 12),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Colors.white24),
                      ),
                    ),
                    items: _categories.map((c) {
                      return DropdownMenuItem<String>(value: c, child: Text(c));
                    }).toList(),
                    onChanged: _isUploading ? null : (val) => setState(() => _category = val ?? 'Other'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Optional note
            TextField(
              controller: _notesController,
              enabled: !_isUploading,
              style: GoogleFonts.inter(color: Colors.white, fontSize: 13),
              decoration: InputDecoration(
                hintText: 'Add optional site note or location description...',
                hintStyle: GoogleFonts.inter(color: Colors.white38, fontSize: 12),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Colors.white24),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Select photos button / preview grid
            if (_selectedFiles.isEmpty)
              InkWell(
                onTap: _isUploading ? null : _pickPhotos,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 36),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.03),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: VianTheme.primaryGold.withOpacity(0.3),
                      style: BorderStyle.solid,
                    ),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.cloud_upload_outlined, color: VianTheme.primaryGold, size: 40),
                      const SizedBox(height: 10),
                      Text(
                        'CLICK TO SELECT SITE PHOTOS',
                        style: GoogleFonts.outfit(
                          color: VianTheme.primaryGold,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          letterSpacing: 1.0,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Supports multiple images (JPEG, PNG)',
                        style: GoogleFonts.inter(color: Colors.white38, fontSize: 11),
                      ),
                    ],
                  ),
                ),
              )
            else ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Selected (${_selectedFiles.length} photos):',
                    style: GoogleFonts.inter(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                  TextButton.icon(
                    onPressed: _isUploading ? null : _pickPhotos,
                    icon: const Icon(Icons.add_photo_alternate_outlined, size: 16, color: VianTheme.primaryGold),
                    label: Text(
                      'Add More',
                      style: GoogleFonts.inter(color: VianTheme.primaryGold, fontSize: 12),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 110,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _selectedFiles.length,
                  separatorBuilder: (context, index) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final file = _selectedFiles[index];
                    return Stack(
                      children: [
                        Container(
                          width: 110,
                          height: 110,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.white24),
                            color: const Color(0xFF27272A),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: file.bytes != null
                              ? Image.memory(file.bytes!, fit: BoxFit.cover)
                              : Center(
                                  child: Text(
                                    file.name,
                                    maxLines: 2,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(color: Colors.white60, fontSize: 10),
                                  ),
                                ),
                        ),
                        if (!_isUploading)
                          Positioned(
                            top: 4,
                            right: 4,
                            child: InkWell(
                              onTap: () => _removePhoto(index),
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  color: Colors.black87,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.close, color: Colors.white, size: 12),
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ),
            ],

            const SizedBox(height: 20),

            // Progress bar
            if (_isUploading) ...[
              LinearProgressIndicator(
                value: _uploadProgress,
                backgroundColor: Colors.white10,
                color: VianTheme.primaryGold,
                minHeight: 6,
                borderRadius: BorderRadius.circular(3),
              ),
              const SizedBox(height: 8),
              Center(
                child: Text(
                  'Uploading to Cloudinary... ${(_uploadProgress * 100).toInt()}%',
                  style: GoogleFonts.inter(color: Colors.white70, fontSize: 11),
                ),
              ),
              const SizedBox(height: 12),
            ],

            // Actions
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: _isUploading ? null : () => Navigator.of(context).pop(),
                  child: Text('Cancel', style: GoogleFonts.inter(color: Colors.white60)),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: _isUploading || _selectedFiles.isEmpty ? null : _uploadPhotos,
                  icon: const Icon(Icons.upload_outlined, size: 18),
                  label: Text(
                    _isUploading ? 'Uploading...' : 'Upload Photos (${_selectedFiles.length})',
                    style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: VianTheme.primaryGold,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
