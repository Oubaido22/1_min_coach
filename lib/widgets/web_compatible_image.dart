import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Widget d'image compatible avec le web
class WebCompatibleImage extends StatelessWidget {
  final String imagePath;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Widget? placeholder;

  const WebCompatibleImage({
    super.key,
    required this.imagePath,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.placeholder,
  });

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      // Sur le web, utiliser Image.network ou un placeholder
      return Container(
        width: width,
        height: height,
        color: Colors.grey[300],
        child: placeholder ?? const Center(
          child: Icon(
            Icons.image,
            size: 50,
            color: Colors.grey,
          ),
        ),
      );
    } else {
      // Sur mobile, utiliser Image.file
      return Image.file(
        File(imagePath),
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            width: width,
            height: height,
            color: Colors.grey[300],
            child: const Center(
              child: Icon(
                Icons.error,
                size: 50,
                color: Colors.red,
              ),
            ),
          );
        },
      );
    }
  }
}
