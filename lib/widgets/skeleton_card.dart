import 'package:flutter/material.dart';

class SkeletonCard extends StatelessWidget {
  final double height;
  final double width;
  final bool isCircular;

  const SkeletonCard({
    super.key,
    this.height = 100,
    this.width = double.infinity,
    this.isCircular = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: width,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: isCircular ? null : BorderRadius.circular(16),
        shape: isCircular ? BoxShape.circle : BoxShape.rectangle,
      ),
      child: const SizedBox.shrink(),
    );
  }
}

class SkeletonText extends StatelessWidget {
  final double width;
  final double height;

  const SkeletonText({
    super.key,
    this.width = double.infinity,
    this.height = 16,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(4),
      ),
      child: const SizedBox.shrink(),
    );
  }
}

class DashboardSkeleton extends StatelessWidget {
  const DashboardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome section skeleton
              _buildWelcomeSkeleton(),
              const SizedBox(height: 30),
              // Attendance section skeleton
              _buildAttendanceSkeleton(),
              const SizedBox(height: 30),
              // Salary section skeleton
              _buildSalarySkeleton(),
              const SizedBox(height: 30),
              // Location section skeleton
              _buildLocationSkeleton(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildWelcomeSkeleton() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          const SkeletonCard(
            width: 60,
            height: 60,
            isCircular: true,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkeletonText(height: 16, width: 100),
                const SizedBox(height: 8),
                SkeletonText(height: 24, width: 150),
                const SizedBox(height: 4),
                SkeletonText(height: 14, width: 200),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceSkeleton() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SkeletonText(height: 20, width: 150),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              SkeletonText(height: 16, width: 80),
              SkeletonCard(width: 80, height: 30),
            ],
          ),
          const SizedBox(height: 16),
          SkeletonText(height: 14, width: 120),
          const SizedBox(height: 8),
          SkeletonText(height: 14, width: 120),
          const SizedBox(height: 16),
          SkeletonCard(width: double.infinity, height: 40),
        ],
      ),
    );
  }

  Widget _buildSalarySkeleton() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SkeletonText(height: 20, width: 150),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              SkeletonText(height: 16, width: 100),
              SkeletonText(height: 16, width: 80),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              SkeletonText(height: 16, width: 100),
              SkeletonText(height: 16, width: 80),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              SkeletonText(height: 16, width: 100),
              SkeletonText(height: 16, width: 80),
            ],
          ),
          const SizedBox(height: 16),
          SkeletonCard(width: double.infinity, height: 40),
        ],
      ),
    );
  }

  Widget _buildLocationSkeleton() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SkeletonText(height: 20, width: 100),
          const SizedBox(height: 16),
          Row(
            children: [
              const Icon(Icons.location_on, color: Colors.grey),
              const SizedBox(width: 8),
              Expanded(
                child: SkeletonText(height: 14, width: 200),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SkeletonCard(width: double.infinity, height: 40),
        ],
      ),
    );
  }
}