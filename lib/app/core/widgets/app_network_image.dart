import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:awnneaapp/app/core/constants/api_constants.dart';
import 'package:awnneaapp/app/core/values/app_colors.dart';
import 'package:awnneaapp/app/data/models/home_models.dart';
import 'skeleton.dart';

/// Network image with a disk + memory cache and a skeleton while it loads.
/// Every remote picture in the app goes through this widget, so a photo is
/// downloaded once and then served from the device.
class AppNetworkImage extends StatelessWidget {
  final String? url;
  final double? width;
  final double? height;
  final BoxFit fit;
  final double radius;
  final Widget? errorWidget;

  const AppNetworkImage({
    super.key,
    required this.url,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.radius = 0,
    this.errorWidget,
  });

  @override
  Widget build(BuildContext context) {
    final resolved = ApiConstants.resolveImageUrl(url);
    final fallback = errorWidget ??
        Container(
          width: width,
          height: height,
          color: Theme.of(context).brightness == Brightness.dark
              ? AppColors.darkInputFill
              : const Color(0xFFF1F3F5),
          alignment: Alignment.center,
          child: Icon(Icons.image_outlined,
              color: Theme.of(context).hintColor, size: _iconSize()),
        );

    if (resolved == null) return _clip(fallback);

    // Decode at the size it is shown, not at full resolution: far less memory.
    final dpr = MediaQuery.maybeOf(context)?.devicePixelRatio ?? 2;
    final cacheW = (width != null && width!.isFinite) ? (width! * dpr).round() : null;

    return _clip(
      CachedNetworkImage(
        imageUrl: resolved,
        width: width,
        height: height,
        fit: fit,
        memCacheWidth: cacheW,
        fadeInDuration: const Duration(milliseconds: 150),
        placeholder: (_, __) => Shimmer(
          child: SkeletonBox(
            width: width,
            height: height ?? 80,
            radius: 0,
          ),
        ),
        errorWidget: (_, __, ___) => fallback,
      ),
    );
  }

  double _iconSize() {
    final w = width ?? height ?? 40;
    return w.isFinite ? (w * 0.4).clamp(16, 40).toDouble() : 28;
  }

  Widget _clip(Widget child) =>
      radius > 0 ? ClipRRect(borderRadius: BorderRadius.circular(radius), child: child) : child;
}

/// Round profile picture; falls back to the person's initial.
class AppAvatar extends StatelessWidget {
  final String? url;
  final String name;
  final double size;

  const AppAvatar({super.key, required this.url, required this.name, this.size = 44});

  @override
  Widget build(BuildContext context) {
    final initial = name.trim().isNotEmpty ? name.trim().characters.first.toUpperCase() : '?';
    final placeholder = Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.primary.withValues(alpha: 0.18),
      ),
      child: Text(
        initial,
        style: TextStyle(
          fontSize: size * 0.42,
          fontWeight: FontWeight.w700,
          color: AppColors.primary,
        ),
      ),
    );
    return ClipOval(
      child: AppNetworkImage(
        url: url,
        width: size,
        height: size,
        errorWidget: placeholder,
      ),
    );
  }
}

/// Category picture: the icon bundled with the app when it is the standard one
/// (instant, works offline), otherwise the hosted icon with a Material icon
/// while it loads or if it cannot be loaded.
class CategoryIcon extends StatelessWidget {
  final Category category;
  final double size;
  final Color? color;

  const CategoryIcon({super.key, required this.category, this.size = 30, this.color});

  @override
  Widget build(BuildContext context) {
    final fallbackIcon = Icon(category.icon, size: size, color: color ?? category.color);
    final bundled = category.bundledIconAsset;
    final remote = category.resolvedIconUrl;

    if (bundled != null) {
      return SvgPicture.asset(bundled, width: size, height: size);
    }
    if (remote != null) {
      if (remote.toLowerCase().endsWith('.svg')) {
        return SvgPicture.network(
          remote,
          width: size,
          height: size,
          placeholderBuilder: (_) => fallbackIcon,
          errorBuilder: (_, __, ___) => fallbackIcon,
        );
      }
      return AppNetworkImage(
        url: remote,
        width: size,
        height: size,
        fit: BoxFit.contain,
        errorWidget: fallbackIcon,
      );
    }
    return fallbackIcon;
  }
}
