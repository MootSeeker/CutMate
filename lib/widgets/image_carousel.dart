import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

/// A widget for displaying a carousel of images with pagination indicator
class ImageCarousel extends StatefulWidget {
  /// Main image URL to display
  final String mainImageUrl;
  
  /// Additional image URLs to display in the carousel
  final List<String> additionalImages;
  
  /// Height of the carousel
  final double height;
  
  /// Border radius of the carousel
  final double borderRadius;

  const ImageCarousel({
    super.key, 
    required this.mainImageUrl,
    required this.additionalImages,
    this.height = 200.0,
    this.borderRadius = 12.0,
  });

  @override
  State<ImageCarousel> createState() => _ImageCarouselState();
}

class _ImageCarouselState extends State<ImageCarousel> {
  late PageController _pageController;
  int _currentPage = 0;
  
  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    // Combine main image with additional images
    final allImages = [widget.mainImageUrl, ...widget.additionalImages];
    
    // If there are no valid images, show a placeholder
    if (allImages.isEmpty || (allImages.length == 1 && allImages.first.isEmpty)) {
      return _buildPlaceholder();
    }
    
    // Filter out empty image URLs
    final validImages = allImages.where((url) => url.isNotEmpty).toList();
    
    // If after filtering we have no valid images, show placeholder
    if (validImages.isEmpty) {
      return _buildPlaceholder();
    }
    
    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(widget.borderRadius),
            topRight: Radius.circular(widget.borderRadius),
          ),
          child: SizedBox(
            height: widget.height,
            child: PageView.builder(
              controller: _pageController,
              itemCount: validImages.length,
              onPageChanged: (index) {
                setState(() {
                  _currentPage = index;
                });
              },
              itemBuilder: (context, index) {
                return _buildImageItem(validImages[index]);
              },
            ),
          ),
        ),
        if (validImages.length > 1)
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                validImages.length,
                (index) => _buildPageIndicator(index == _currentPage),
              ),
            ),
          ),
      ],
    );
  }
  
  Widget _buildImageItem(String imageUrl) {
    return CachedNetworkImage(
      imageUrl: imageUrl,
      fit: BoxFit.cover,
      width: double.infinity,
      placeholder: (context, url) => const Center(
        child: CircularProgressIndicator(),
      ),
      errorWidget: (context, url, error) => _buildErrorWidget(),
    );
  }
  
  Widget _buildPageIndicator(bool isActive) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4.0),
      height: 8.0,
      width: isActive ? 24.0 : 8.0,
      decoration: BoxDecoration(
        color: isActive 
            ? Theme.of(context).primaryColor 
            : Theme.of(context).primaryColor.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
  
  Widget _buildPlaceholder() {
    return Container(
      height: widget.height,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(widget.borderRadius),
          topRight: Radius.circular(widget.borderRadius),
        ),
      ),
      child: const Center(
        child: Icon(
          Icons.restaurant,
          size: 48,
          color: Colors.grey,
        ),
      ),
    );
  }
  
  Widget _buildErrorWidget() {
    return Container(
      color: Colors.grey[200],
      child: const Center(
        child: Icon(
          Icons.error_outline,
          size: 48,
          color: Colors.grey,
        ),
      ),
    );
  }
}
