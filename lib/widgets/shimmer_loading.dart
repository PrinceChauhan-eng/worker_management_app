import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class ShimmerLoading extends StatelessWidget {
  final double height;
  final double? width;
  final EdgeInsetsGeometry margin;
  final EdgeInsetsGeometry padding;
  final BorderRadius borderRadius;

  const ShimmerLoading({
    super.key,
    this.height = 20,
    this.width,
    this.margin = EdgeInsets.zero,
    this.padding = EdgeInsets.zero,
    this.borderRadius = const BorderRadius.all(Radius.circular(8)),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      padding: padding,
      child: Shimmer.fromColors(
        baseColor: Colors.grey[300]!,
        highlightColor: Colors.grey[100]!,
        child: Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: borderRadius,
          ),
        ),
      ),
    );
  }
}

class ShimmerCard extends StatelessWidget {
  final double height;
  final EdgeInsetsGeometry margin;

  const ShimmerCard({
    super.key,
    this.height = 120,
    this.margin = const EdgeInsets.all(16),
  });

  @override
  Widget build(BuildContext context) {
    return ShimmerLoading(
      height: height,
      margin: margin,
      borderRadius: BorderRadius.circular(16),
    );
  }
}

class ShimmerList extends StatelessWidget {
  final int itemCount;
  final double itemHeight;
  final EdgeInsetsGeometry padding;

  const ShimmerList({
    super.key,
    this.itemCount = 5,
    this.itemHeight = 80,
    this.padding = const EdgeInsets.all(16),
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Column(
        children: List.generate(
          itemCount,
          (index) => ShimmerLoading(
            height: itemHeight,
            margin: const EdgeInsets.only(bottom: 12),
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}