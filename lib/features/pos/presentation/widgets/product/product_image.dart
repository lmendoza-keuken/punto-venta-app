import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class ProductImage extends StatelessWidget {
  const ProductImage({
    super.key,
    required this.imageUrl,
    this.fit = BoxFit.contain,
    this.width,
    this.height,
    this.alignment = Alignment.center,
    this.placeholder,
    this.error,
  });

  final String imageUrl;
  final BoxFit fit;
  final double? width;
  final double? height;
  final Alignment alignment;
  final Widget? placeholder;
  final Widget? error;

  static bool isAssetUrl(String url) => url.startsWith('asset:');

  static String assetPathFromUrl(String url) => url.substring('asset:'.length);

  @override
  Widget build(BuildContext context) {
    if (isAssetUrl(imageUrl)) {
      return Image.asset(
        assetPathFromUrl(imageUrl),
        fit: fit,
        width: width,
        height: height,
        alignment: alignment,
        errorBuilder: (context, _, __) => error ?? const SizedBox.shrink(),
      );
    }

    return CachedNetworkImage(
      imageUrl: imageUrl,
      fit: fit,
      width: width,
      height: height,
      alignment: alignment,
      fadeInDuration: const Duration(milliseconds: 150),
      placeholder: (context, url) =>
          placeholder ?? const SizedBox.shrink(),
      errorWidget: (context, url, err) => error ?? const SizedBox.shrink(),
    );
  }
}
