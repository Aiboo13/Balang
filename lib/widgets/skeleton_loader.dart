import 'package:flutter/material.dart';

/// Widget shimmer/skeleton dasar — berkedip dari abu muda ke abu lebih terang
class _ShimmerBox extends StatefulWidget {
  final double? width; // nullable agar bisa expand
  final double height;
  final BorderRadius borderRadius;

  const _ShimmerBox({
    this.width,
    required this.height,
    this.borderRadius = const BorderRadius.all(Radius.circular(8)),
  });

  @override
  State<_ShimmerBox> createState() => _ShimmerBoxState();
}

class _ShimmerBoxState extends State<_ShimmerBox>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.3, end: 0.7).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (_, __) => Container(
        width: widget.width ?? double.infinity, // jika null akan mengisi space kosong
        height: widget.height,
        decoration: BoxDecoration(
          borderRadius: widget.borderRadius,
          color: Colors.grey.withOpacity(_animation.value),
        ),
      ),
    );
  }
}

/// Skeleton card untuk HomePage
class HomeCardSkeleton extends StatelessWidget {
  const HomeCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Judul + badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: _ShimmerBox(height: 14),
              ),
              const SizedBox(width: 10),
              _ShimmerBox(
                width: 70,
                height: 22,
                borderRadius: BorderRadius.circular(20),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _ShimmerBox(
                width: 110,
                height: 85,
                borderRadius: BorderRadius.circular(12),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _ShimmerBox(height: 12),
                    SizedBox(height: 6),
                    _ShimmerBox(width: 120, height: 12),
                    SizedBox(height: 12),
                    _ShimmerBox(width: 60, height: 11),
                    SizedBox(height: 4),
                    _ShimmerBox(width: 90, height: 11),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Skeleton card untuk HistoryPage
class HistoryCardSkeleton extends StatelessWidget {
  const HistoryCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _ShimmerBox(
                width: 85,
                height: 85,
                borderRadius: BorderRadius.circular(12),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Di-Expanded bray biar ga overflow pas loading layar sempit
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Expanded(
                          child: _ShimmerBox(height: 14),
                        ),
                        const SizedBox(width: 10),
                        _ShimmerBox(
                          width: 60,
                          height: 20,
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const _ShimmerBox(height: 11),
                    const SizedBox(height: 4),
                    const _ShimmerBox(width: 160, height: 11),
                    const SizedBox(height: 8),
                    const _ShimmerBox(width: 100, height: 11),
                    const SizedBox(height: 4),
                    const _ShimmerBox(width: 80, height: 11),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Divider(height: 1),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const _ShimmerBox(width: 80, height: 11),
              _ShimmerBox(
                width: 60,
                height: 22,
                borderRadius: BorderRadius.circular(20),
              ),
            ],
          ),
        ],
      ),
    );
  }
}