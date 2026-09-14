import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';
import '../theme/theme.dart';

/// Fullscreen read-only photo viewer for Clients and Architects
class ClientPhotoViewerModal extends StatefulWidget {
  final List<dynamic> photos;
  final int initialIndex;
  final String projectName;

  const ClientPhotoViewerModal({
    Key? key,
    required this.photos,
    this.initialIndex = 0,
    required this.projectName,
  }) : super(key: key);

  @override
  State<ClientPhotoViewerModal> createState() => _ClientPhotoViewerModalState();
}

class _ClientPhotoViewerModalState extends State<ClientPhotoViewerModal> {
  late PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  String _resolvePhotoUrl(dynamic url) {
    if (url == null) return '';
    final str = url.toString();
    if (str.startsWith('http://') || str.startsWith('https://')) return str;
    if (str.startsWith('/')) {
      return '${ApiService.baseUrl.replaceAll('/api', '')}$str';
    }
    return str;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.photos.isEmpty) {
      return const Dialog(
        backgroundColor: Colors.black,
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Text('No photos to display', style: TextStyle(color: Colors.white)),
        ),
      );
    }

    final currentPhoto = widget.photos[_currentIndex];
    final String category = currentPhoto['category'] ?? 'Site Progress';
    final String? description = currentPhoto['description'] ?? currentPhoto['notes'];
    final String? uploadedAt = currentPhoto['createdAt']?.toString().split('T').first;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Photo PageView
          PageView.builder(
            controller: _pageController,
            itemCount: widget.photos.length,
            onPageChanged: (index) {
              setState(() => _currentIndex = index);
            },
            itemBuilder: (context, index) {
              final p = widget.photos[index];
              final url = _resolvePhotoUrl(p['url'] ?? p['fileUrl'] ?? p['photoUrl']);
              return InteractiveViewer(
                minScale: 0.8,
                maxScale: 4.0,
                child: Center(
                  child: Image.network(
                    url,
                    fit: BoxFit.contain,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return const Center(
                        child: CircularProgressIndicator(color: VianTheme.primaryGold),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.broken_image_outlined, color: Colors.white38, size: 48),
                            const SizedBox(height: 8),
                            Text(
                              'Unable to load photo',
                              style: GoogleFonts.inter(color: Colors.white54, fontSize: 12),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              );
            },
          ),

          // Top Bar (Project Name + Photo counter + Close)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.black87, Colors.transparent],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: SafeArea(
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white, size: 24),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.projectName,
                            style: GoogleFonts.outfit(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Photo ${_currentIndex + 1} of ${widget.photos.length} • $category',
                            style: GoogleFonts.inter(color: Colors.white70, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Previous / Next Nav Buttons (Desktop/Tablet)
          if (widget.photos.length > 1) ...[
            if (_currentIndex > 0)
              Positioned(
                left: 16,
                top: 0,
                bottom: 0,
                child: Center(
                  child: IconButton(
                    icon: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white24),
                      ),
                      child: const Icon(Icons.chevron_left, color: Colors.white, size: 28),
                    ),
                    onPressed: () {
                      _pageController.previousPage(
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeInOut,
                      );
                    },
                  ),
                ),
              ),
            if (_currentIndex < widget.photos.length - 1)
              Positioned(
                right: 16,
                top: 0,
                bottom: 0,
                child: Center(
                  child: IconButton(
                    icon: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white24),
                      ),
                      child: const Icon(Icons.chevron_right, color: Colors.white, size: 28),
                    ),
                    onPressed: () {
                      _pageController.nextPage(
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeInOut,
                      );
                    },
                  ),
                ),
              ),
          ],

          // Bottom Bar (Metadata info)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.transparent, Colors.black87],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: SafeArea(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (description != null && description.isNotEmpty) ...[
                      Text(
                        description,
                        style: GoogleFonts.inter(color: Colors.white, fontSize: 13),
                      ),
                      const SizedBox(height: 6),
                    ],
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: VianTheme.primaryGold.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            category.toUpperCase(),
                            style: GoogleFonts.outfit(
                              color: VianTheme.primaryGold,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        if (uploadedAt != null) ...[
                          const SizedBox(width: 10),
                          Text(
                            'Date: $uploadedAt',
                            style: GoogleFonts.inter(color: Colors.white54, fontSize: 11),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
