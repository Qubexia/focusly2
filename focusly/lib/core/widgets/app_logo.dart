import 'package:flutter/material.dart';

import '../constants/app_assets.dart';

/// Brand logo used on splash, auth, and other branded surfaces.
class AppLogo extends StatelessWidget {
  const AppLogo({
    super.key,
    this.width = 200,
    this.height = 200,
    this.fit = BoxFit.contain,
    this.borderRadius,
  });

  final double width;
  final double height;
  final BoxFit fit;
  final BorderRadius? borderRadius;

  @override
  Widget build(BuildContext context) {
    final image = Image.asset(
      AppAssets.logo,
      width: width,
      height: height,
      fit: fit,
      filterQuality: FilterQuality.high,
    );

    if (borderRadius == null) {
      return image;
    }

    return ClipRRect(
      borderRadius: borderRadius!,
      child: image,
    );
  }
}
