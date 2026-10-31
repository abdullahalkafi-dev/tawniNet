import 'package:flutter/material.dart';
import 'package:awnneaapp/app/core/values/app_colors.dart';

/// Loading placeholders ("skeletons") that look like the content that is coming.
///
/// Wrap a group of [SkeletonBox]/[SkeletonCircle]/[SkeletonLine] widgets in a
/// single [Shimmer]: one animation drives every block inside it, so a long
/// skeleton list costs almost nothing. Card backgrounds stay still; only the
/// grey blocks shimmer.
class Shimmer extends StatefulWidget {
  final Widget child;
  const Shimmer({super.key, required this.child});

  @override
  State<Shimmer> createState() => _ShimmerState();
}

class _ShimmerState extends State<Shimmer> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Skeletons are decoration only: screen readers skip them.
    return ExcludeSemantics(
      child: _ShimmerScope(notifier: _controller, child: widget.child),
    );
  }
}

class _ShimmerScope extends InheritedNotifier<AnimationController> {
  const _ShimmerScope({required AnimationController super.notifier, required super.child});

  static AnimationController? of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_ShimmerScope>()?.notifier;
}

class _SlideGradient extends GradientTransform {
  final double percent;
  const _SlideGradient(this.percent);

  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) =>
      Matrix4.translationValues(bounds.width * percent, 0, 0);
}

/// A grey block that shimmers when inside a [Shimmer].
class SkeletonBox extends StatelessWidget {
  final double? width;
  final double height;
  final double radius;
  final BoxShape shape;

  const SkeletonBox({
    super.key,
    this.width,
    required this.height,
    this.radius = 8,
    this.shape = BoxShape.rectangle,
  });

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final base = dark ? const Color(0xFF2E2F33) : const Color(0xFFE9ECEF);
    final highlight = dark ? const Color(0xFF3F4045) : const Color(0xFFF6F7F8);
    final controller = _ShimmerScope.of(context);

    BoxDecoration decoration(double? t) => BoxDecoration(
          shape: shape,
          borderRadius: shape == BoxShape.circle ? null : BorderRadius.circular(radius),
          color: t == null ? base : null,
          gradient: t == null
              ? null
              : LinearGradient(
                  begin: const Alignment(-1, -0.3),
                  end: const Alignment(1, 0.3),
                  colors: [base, highlight, base],
                  stops: const [0.35, 0.5, 0.65],
                  transform: _SlideGradient(-1 + 2 * t),
                ),
        );

    if (controller == null) {
      return Container(width: width, height: height, decoration: decoration(null));
    }
    return AnimatedBuilder(
      animation: controller,
      builder: (_, __) =>
          Container(width: width, height: height, decoration: decoration(controller.value)),
    );
  }
}

class SkeletonCircle extends StatelessWidget {
  final double size;
  const SkeletonCircle({super.key, required this.size});

  @override
  Widget build(BuildContext context) =>
      SkeletonBox(width: size, height: size, shape: BoxShape.circle);
}

/// A line of text. [widthFactor] is the share of the available width.
class SkeletonLine extends StatelessWidget {
  final double height;
  final double widthFactor;
  const SkeletonLine({super.key, this.height = 12, this.widthFactor = 1});

  @override
  Widget build(BuildContext context) {
    return FractionallySizedBox(
      widthFactor: widthFactor,
      alignment: AlignmentDirectional.centerStart,
      child: SkeletonBox(height: height, radius: 6),
    );
  }
}

/// Card surface used by list skeletons (matches the real cards).
class _SkeletonCard extends StatelessWidget {
  final Widget child;
  const _SkeletonCard({required this.child});

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: dark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: dark ? AppColors.darkBorderSubtle : const Color(0xFFEDEFF1)),
      ),
      child: child,
    );
  }
}

// ─── Ready-made skeletons ─────────────────────────────────

/// A vertical list of [count] skeleton rows built by [itemBuilder].
class SkeletonList extends StatelessWidget {
  final int count;
  final Widget Function(BuildContext context, int index) itemBuilder;
  final EdgeInsetsGeometry padding;
  final double spacing;
  final bool shrinkWrap;
  final ScrollPhysics? physics;

  const SkeletonList({
    super.key,
    this.count = 6,
    required this.itemBuilder,
    this.padding = const EdgeInsets.fromLTRB(20, 12, 20, 20),
    this.spacing = 12,
    this.shrinkWrap = false,
    this.physics = const NeverScrollableScrollPhysics(),
  });

  @override
  Widget build(BuildContext context) {
    return Shimmer(
      child: ListView.separated(
        padding: padding,
        shrinkWrap: shrinkWrap,
        physics: physics,
        itemCount: count,
        separatorBuilder: (_, __) => SizedBox(height: spacing),
        itemBuilder: itemBuilder,
      ),
    );
  }
}

/// Helper/worker card: avatar, name, category, rating and price.
class HelperCardSkeleton extends StatelessWidget {
  const HelperCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return const _SkeletonCard(
      child: Row(
        children: [
          SkeletonCircle(size: 56),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkeletonLine(height: 14, widthFactor: 0.55),
                SizedBox(height: 8),
                SkeletonLine(height: 11, widthFactor: 0.4),
                SizedBox(height: 8),
                SkeletonLine(height: 11, widthFactor: 0.7),
              ],
            ),
          ),
          SizedBox(width: 12),
          SkeletonBox(width: 54, height: 24, radius: 12),
        ],
      ),
    );
  }
}

/// Job / booking card: title, status chip, details, footer.
class JobCardSkeleton extends StatelessWidget {
  const JobCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return const _SkeletonCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: SkeletonLine(height: 15, widthFactor: 0.6)),
              SizedBox(width: 12),
              SkeletonBox(width: 70, height: 22, radius: 11),
            ],
          ),
          SizedBox(height: 12),
          SkeletonLine(height: 11, widthFactor: 0.9),
          SizedBox(height: 8),
          SkeletonLine(height: 11, widthFactor: 0.5),
          SizedBox(height: 14),
          Row(
            children: [
              SkeletonCircle(size: 28),
              SizedBox(width: 8),
              Expanded(child: SkeletonLine(height: 11, widthFactor: 0.35)),
              SkeletonBox(width: 60, height: 16, radius: 6),
            ],
          ),
        ],
      ),
    );
  }
}

/// Conversation row: avatar, name, last message, time.
class ChatTileSkeleton extends StatelessWidget {
  const ChatTileSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        SkeletonCircle(size: 52),
        SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SkeletonLine(height: 13, widthFactor: 0.45),
              SizedBox(height: 8),
              SkeletonLine(height: 11, widthFactor: 0.8),
            ],
          ),
        ),
        SizedBox(width: 12),
        SkeletonBox(width: 34, height: 10, radius: 5),
      ],
    );
  }
}

/// Grid of category tiles (icon + label).
class CategoryGridSkeleton extends StatelessWidget {
  final int count;
  final int columns;
  const CategoryGridSkeleton({super.key, this.count = 8, this.columns = 4});

  @override
  Widget build(BuildContext context) {
    return Shimmer(
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: count,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: columns,
          mainAxisSpacing: 16,
          crossAxisSpacing: 12,
          childAspectRatio: 0.78,
        ),
        itemBuilder: (_, __) => const Column(
          children: [
            Expanded(child: SkeletonBox(height: double.infinity, radius: 16)),
            SizedBox(height: 8),
            SkeletonLine(height: 10, widthFactor: 0.8),
          ],
        ),
      ),
    );
  }
}

/// Wallet / stats tile.
class StatTileSkeleton extends StatelessWidget {
  const StatTileSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return const _SkeletonCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SkeletonLine(height: 11, widthFactor: 0.4),
          SizedBox(height: 10),
          SkeletonLine(height: 22, widthFactor: 0.6),
        ],
      ),
    );
  }
}

/// Plain block page (detail screens): header image + a few lines.
class DetailSkeleton extends StatelessWidget {
  const DetailSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return const Shimmer(
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SkeletonBox(height: 160, radius: 16),
            SizedBox(height: 18),
            SkeletonLine(height: 18, widthFactor: 0.7),
            SizedBox(height: 12),
            SkeletonLine(height: 12),
            SizedBox(height: 8),
            SkeletonLine(height: 12, widthFactor: 0.9),
            SizedBox(height: 8),
            SkeletonLine(height: 12, widthFactor: 0.6),
            SizedBox(height: 24),
            HelperCardSkeleton(),
          ],
        ),
      ),
    );
  }
}

/// Summary card followed by a list of rows: wallet, earnings, connects pages.
class SummaryListSkeleton extends StatelessWidget {
  final int rows;
  const SummaryListSkeleton({super.key, this.rows = 5});

  @override
  Widget build(BuildContext context) {
    return Shimmer(
      child: ListView(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        children: [
          const SkeletonBox(height: 120, radius: 16),
          const SizedBox(height: 24),
          const SkeletonLine(height: 16, widthFactor: 0.35),
          const SizedBox(height: 14),
          for (var i = 0; i < rows; i++) ...[
            const Row(
              children: [
                SkeletonCircle(size: 40),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SkeletonLine(height: 12, widthFactor: 0.6),
                      SizedBox(height: 8),
                      SkeletonLine(height: 10, widthFactor: 0.3),
                    ],
                  ),
                ),
                SkeletonBox(width: 50, height: 14, radius: 6),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ],
      ),
    );
  }
}
