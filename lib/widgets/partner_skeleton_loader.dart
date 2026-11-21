import 'package:flutter/material.dart';
import '../core/app_colors.dart';

/// Shimmer widget that animates a radiant gradient over child placeholder shapes.
class ShimmerLoading extends StatefulWidget {
  final Widget child;
  final Color baseColor;
  final Color highlightColor;
  final Duration duration;

  const ShimmerLoading({
    super.key,
    required this.child,
    this.baseColor = const Color(0xFFE8EEF5),
    this.highlightColor = const Color(0xFFF6F9FC),
    this.duration = const Duration(milliseconds: 1300),
  });

  @override
  State<ShimmerLoading> createState() => _ShimmerLoadingState();
}

class _ShimmerLoadingState extends State<ShimmerLoading> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration)..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: const Alignment(-1.0, -0.3),
              end: const Alignment(1.0, 0.3),
              stops: const [0.1, 0.5, 0.9],
              colors: [
                widget.baseColor,
                widget.highlightColor,
                widget.baseColor,
              ],
              transform: _SlidingGradientTransform(slidePercent: _controller.value),
            ).createShader(bounds);
          },
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

class _SlidingGradientTransform extends GradientTransform {
  final double slidePercent;
  const _SlidingGradientTransform({required this.slidePercent});

  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) {
    return Matrix4.translationValues(bounds.width * (slidePercent * 2 - 1), 0.0, 0.0);
  }
}

/// A versatile skeleton shape element
class SkeletonBox extends StatelessWidget {
  final double? width;
  final double? height;
  final double borderRadius;
  final BoxShape shape;
  final EdgeInsetsGeometry? margin;
  final Color color;

  const SkeletonBox({
    super.key,
    this.width,
    this.height,
    this.borderRadius = 8,
    this.shape = BoxShape.rectangle,
    this.margin,
    this.color = const Color(0xFFE2E8F0),
  });

  const SkeletonBox.circle({
    super.key,
    required double size,
    this.margin,
    this.color = const Color(0xFFE2E8F0),
  })  : width = size,
        height = size,
        borderRadius = 0,
        shape = BoxShape.circle;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      margin: margin,
      decoration: BoxDecoration(
        color: color,
        shape: shape,
        borderRadius: shape == BoxShape.circle ? null : BorderRadius.circular(borderRadius),
      ),
    );
  }
}

/// Skeleton for Dashboard Home Tab (Counts, Progress, Quick Links)
class PartnerDashboardHomeSkeleton extends StatelessWidget {
  const PartnerDashboardHomeSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ShimmerLoading(
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.only(left: 16, right: 16, top: 12, bottom: 120),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hero banner card
            const SkeletonBox(
              height: 140,
              width: double.infinity,
              borderRadius: 20,
              margin: EdgeInsets.only(bottom: 20),
            ),

            // Profile completion card
            Container(
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.withAlpha(25)),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      SkeletonBox(width: 140, height: 16),
                      SkeletonBox(width: 40, height: 16),
                    ],
                  ),
                  SizedBox(height: 12),
                  SkeletonBox(height: 8, width: double.infinity, borderRadius: 4),
                  SizedBox(height: 12),
                  Row(
                    children: [
                      SkeletonBox(width: 80, height: 26, borderRadius: 13),
                      SizedBox(width: 8),
                      SkeletonBox(width: 90, height: 26, borderRadius: 13),
                    ],
                  ),
                ],
              ),
            ),

            // Section title
            const SkeletonBox(width: 130, height: 18, margin: EdgeInsets.only(bottom: 14)),

            // 4 Count stat cards in grid
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 14,
              mainAxisSpacing: 14,
              childAspectRatio: 1.35,
              children: List.generate(4, (index) => Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.withAlpha(25)),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        SkeletonBox.circle(size: 34),
                        SkeletonBox(width: 20, height: 14),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SkeletonBox(width: 50, height: 22, borderRadius: 4),
                        SizedBox(height: 4),
                        SkeletonBox(width: 80, height: 12, borderRadius: 3),
                      ],
                    ),
                  ],
                ),
              )),
            ),

            const SizedBox(height: 24),
            // Quick action heading
            const SkeletonBox(width: 150, height: 18, margin: EdgeInsets.only(bottom: 14)),

            // Quick action tiles
            Column(
              children: List.generate(3, (index) => Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.grey.withAlpha(25)),
                ),
                child: const Row(
                  children: [
                    SkeletonBox.circle(size: 38),
                    SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SkeletonBox(width: 140, height: 14),
                          SizedBox(height: 6),
                          SkeletonBox(width: 100, height: 11),
                        ],
                      ),
                    ),
                    SkeletonBox(width: 16, height: 16, borderRadius: 4),
                  ],
                ),
              )),
            ),
          ],
        ),
      ),
    );
  }
}

/// Skeleton for Appointments List Screen (Today, Upcoming, Complete, Cancelled)
class PartnerAppointmentsSkeleton extends StatelessWidget {
  final int itemCount;
  const PartnerAppointmentsSkeleton({super.key, this.itemCount = 4});

  @override
  Widget build(BuildContext context) {
    return ShimmerLoading(
      child: ListView.builder(
        padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 135),
        physics: const NeverScrollableScrollPhysics(),
        itemCount: itemCount,
        itemBuilder: (context, index) => Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.grey.withAlpha(25)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top date / header ribbon
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: const BoxDecoration(
                  color: Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        SkeletonBox(width: 16, height: 16, borderRadius: 4),
                        SizedBox(width: 8),
                        SkeletonBox(width: 110, height: 14),
                      ],
                    ),
                    SkeletonBox(width: 70, height: 22, borderRadius: 11),
                  ],
                ),
              ),

              // Body content
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SkeletonBox.circle(size: 46),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SkeletonBox(width: 150, height: 16),
                              const SizedBox(height: 6),
                              const SkeletonBox(width: 110, height: 12),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  const SkeletonBox(width: 80, height: 20, borderRadius: 6),
                                  const SizedBox(width: 8),
                                  SkeletonBox(width: 65, height: 20, borderRadius: 6, color: AppColors.teal.withAlpha(40)),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    const Divider(height: 1, color: Color(0xFFF1F5F9)),
                    const SizedBox(height: 12),
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        SkeletonBox(width: 100, height: 14),
                        Row(
                          children: [
                            SkeletonBox(width: 85, height: 32, borderRadius: 10),
                            SizedBox(width: 8),
                            SkeletonBox(width: 85, height: 32, borderRadius: 10),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Skeleton for Doctors Directory Screen (showdoctors.dart)
class PartnerDoctorsSkeleton extends StatelessWidget {
  final int itemCount;
  const PartnerDoctorsSkeleton({super.key, this.itemCount = 4});

  @override
  Widget build(BuildContext context) {
    return ShimmerLoading(
      child: ListView.builder(
        padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 135),
        physics: const NeverScrollableScrollPhysics(),
        itemCount: itemCount,
        itemBuilder: (context, index) => Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.grey.withAlpha(25)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SkeletonBox.circle(size: 52),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SkeletonBox(width: 160, height: 16),
                        SizedBox(height: 6),
                        SkeletonBox(width: 120, height: 13),
                        SizedBox(height: 6),
                        SkeletonBox(width: 90, height: 20, borderRadius: 6),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      SkeletonBox(width: 32, height: 32, borderRadius: 8, color: Colors.blue.withAlpha(25)),
                      const SizedBox(width: 6),
                      SkeletonBox(width: 32, height: 32, borderRadius: 8, color: Colors.red.withAlpha(25)),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 14),
              const Divider(height: 1, color: Color(0xFFF1F5F9)),
              const SizedBox(height: 10),
              const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      SkeletonBox(width: 14, height: 14, borderRadius: 3),
                      SizedBox(width: 6),
                      SkeletonBox(width: 110, height: 12),
                    ],
                  ),
                  SkeletonBox(width: 80, height: 16, borderRadius: 4),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Skeleton for Pathology Tests Directory Screen (showtests.dart)
class PartnerTestsSkeleton extends StatelessWidget {
  final int itemCount;
  const PartnerTestsSkeleton({super.key, this.itemCount = 4});

  @override
  Widget build(BuildContext context) {
    return ShimmerLoading(
      child: ListView.builder(
        padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 135),
        physics: const NeverScrollableScrollPhysics(),
        itemCount: itemCount,
        itemBuilder: (context, index) => Container(
          margin: const EdgeInsets.only(bottom: 14),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.withAlpha(25)),
          ),
          child: Row(
            children: [
              const SkeletonBox.circle(size: 44),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SkeletonBox(width: 150, height: 15),
                    SizedBox(height: 6),
                    SkeletonBox(width: 90, height: 12),
                    SizedBox(height: 8),
                    SkeletonBox(width: 70, height: 18, borderRadius: 5),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const SkeletonBox(width: 60, height: 18, borderRadius: 4),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      SkeletonBox(width: 30, height: 30, borderRadius: 8, color: Colors.blue.withAlpha(25)),
                      const SizedBox(width: 6),
                      SkeletonBox(width: 30, height: 30, borderRadius: 8, color: Colors.red.withAlpha(25)),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Skeleton for Patient Requests / Inquiries Screen (patient_lists.dart)
class PartnerPatientInquiriesSkeleton extends StatelessWidget {
  final int itemCount;
  const PartnerPatientInquiriesSkeleton({super.key, this.itemCount = 4});

  @override
  Widget build(BuildContext context) {
    return ShimmerLoading(
      child: ListView.builder(
        padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 135),
        physics: const NeverScrollableScrollPhysics(),
        itemCount: itemCount,
        itemBuilder: (context, index) => Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.grey.withAlpha(25)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SkeletonBox.circle(size: 46),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SkeletonBox(width: 130, height: 16),
                        SizedBox(height: 5),
                        SkeletonBox(width: 100, height: 12),
                      ],
                    ),
                  ),
                  SkeletonBox(width: 70, height: 22, borderRadius: 11, color: AppColors.teal.withAlpha(35)),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SkeletonBox(width: double.infinity, height: 11),
                    SizedBox(height: 6),
                    SkeletonBox(width: 180, height: 11),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      SkeletonBox(width: 14, height: 14, borderRadius: 3),
                      SizedBox(width: 6),
                      SkeletonBox(width: 90, height: 12),
                    ],
                  ),
                  SkeletonBox(width: 100, height: 32, borderRadius: 8),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Skeleton for Profile / Clinic Details Form Screen (doctocontact, opdcontact, pathologycontact)
class PartnerFormProfileSkeleton extends StatelessWidget {
  const PartnerFormProfileSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ShimmerLoading(
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 135),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Banner placeholder
            Container(
              height: 140,
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.withAlpha(40)),
              ),
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SkeletonBox.circle(size: 40),
                    SizedBox(height: 8),
                    SkeletonBox(width: 130, height: 14),
                  ],
                ),
              ),
            ),

            // Form cards
            ...List.generate(5, (index) => Container(
              margin: const EdgeInsets.only(bottom: 14),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.grey.withAlpha(25)),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SkeletonBox(width: 110, height: 13),
                  SizedBox(height: 10),
                  SkeletonBox(height: 44, width: double.infinity, borderRadius: 10),
                ],
              ),
            )),

            const SizedBox(height: 10),
            // Save action button
            const SkeletonBox(
              height: 50,
              width: double.infinity,
              borderRadius: 14,
            ),
          ],
        ),
      ),
    );
  }
}

/// Skeleton for Patient Medical History Screen
class PartnerMedicalHistorySkeleton extends StatelessWidget {
  const PartnerMedicalHistorySkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ShimmerLoading(
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Patient Header Card
            Container(
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.only(bottom: 18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Colors.grey.withAlpha(25)),
              ),
              child: const Row(
                children: [
                  SkeletonBox.circle(size: 56),
                  SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SkeletonBox(width: 160, height: 18),
                        SizedBox(height: 6),
                        SkeletonBox(width: 120, height: 13),
                        SizedBox(height: 8),
                        SkeletonBox(width: 90, height: 20, borderRadius: 6),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Vitals 4 cards
            const SkeletonBox(width: 140, height: 16, margin: EdgeInsets.only(bottom: 12)),
            Row(
              children: List.generate(3, (index) => Expanded(
                child: Container(
                  margin: EdgeInsets.only(right: index < 2 ? 10 : 0),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.grey.withAlpha(25)),
                  ),
                  child: const Column(
                    children: [
                      SkeletonBox.circle(size: 28),
                      SizedBox(height: 8),
                      SkeletonBox(width: 50, height: 16),
                      SizedBox(height: 4),
                      SkeletonBox(width: 40, height: 11),
                    ],
                  ),
                ),
              )),
            ),

            const SizedBox(height: 22),
            const SkeletonBox(width: 160, height: 16, margin: EdgeInsets.only(bottom: 12)),
            ...List.generate(3, (index) => Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.grey.withAlpha(25)),
              ),
              child: const Row(
                children: [
                  SkeletonBox(width: 40, height: 40, borderRadius: 10),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SkeletonBox(width: 140, height: 14),
                        SizedBox(height: 6),
                        SkeletonBox(width: 90, height: 11),
                      ],
                    ),
                  ),
                  SkeletonBox(width: 24, height: 24, borderRadius: 6),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }
}

/// Skeleton for Patient Profile View Screen (patient_profile_view.dart)
class PartnerPatientProfileSkeleton extends StatelessWidget {
  const PartnerPatientProfileSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ShimmerLoading(
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Profile card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.grey.withAlpha(25)),
              ),
              child: const Column(
                children: [
                  SkeletonBox.circle(size: 70),
                  SizedBox(height: 12),
                  SkeletonBox(width: 160, height: 18),
                  SizedBox(height: 6),
                  SkeletonBox(width: 120, height: 13),
                  SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SkeletonBox(width: 70, height: 24, borderRadius: 12),
                      SizedBox(width: 8),
                      SkeletonBox(width: 90, height: 24, borderRadius: 12),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            // Tab switcher bar
            Container(
              height: 46,
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                children: [
                  Expanded(child: SkeletonBox(height: 38, borderRadius: 10)),
                  SizedBox(width: 8),
                  Expanded(child: SkeletonBox(height: 38, borderRadius: 10)),
                ],
              ),
            ),
            const SizedBox(height: 18),
            ...List.generate(3, (index) => Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.grey.withAlpha(25)),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SkeletonBox(width: 140, height: 14),
                  SizedBox(height: 8),
                  SkeletonBox(width: double.infinity, height: 12),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }
}

/// Skeleton for Medical Card Access Tab (medical_card_access.dart)
class PartnerMedicalCardSkeleton extends StatelessWidget {
  const PartnerMedicalCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ShimmerLoading(
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Search Input Box
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.withAlpha(25)),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SkeletonBox(width: 150, height: 14),
                  SizedBox(height: 10),
                  SkeletonBox(height: 48, width: double.infinity, borderRadius: 12),
                  SizedBox(height: 12),
                  SkeletonBox(height: 46, width: double.infinity, borderRadius: 12),
                ],
              ),
            ),
            const SizedBox(height: 20),
            // Card Preview Area
            Container(
              height: 190,
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.grey.withAlpha(25)),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      SkeletonBox(width: 110, height: 16),
                      SkeletonBox.circle(size: 32),
                    ],
                  ),
                  SkeletonBox(width: 180, height: 22, borderRadius: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      SkeletonBox(width: 90, height: 14),
                      SkeletonBox(width: 60, height: 14),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Skeleton for Notifications Screen (notifications.dart)
class PartnerNotificationsSkeleton extends StatelessWidget {
  final int itemCount;
  const PartnerNotificationsSkeleton({super.key, this.itemCount = 6});

  @override
  Widget build(BuildContext context) {
    return ShimmerLoading(
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        physics: const NeverScrollableScrollPhysics(),
        itemCount: itemCount,
        itemBuilder: (context, index) => Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.grey.withAlpha(25)),
          ),
          child: const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SkeletonBox.circle(size: 38),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SkeletonBox(width: 160, height: 14),
                    SizedBox(height: 6),
                    SkeletonBox(width: double.infinity, height: 12),
                    SizedBox(height: 8),
                    SkeletonBox(width: 70, height: 10),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Skeleton for Help & Support Screen (help.dart)
class PartnerHelpSkeleton extends StatelessWidget {
  const PartnerHelpSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ShimmerLoading(
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top emergency banner
            const SkeletonBox(
              height: 90,
              width: double.infinity,
              borderRadius: 16,
              margin: EdgeInsets.only(bottom: 16),
            ),
            // Contact tiles
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.grey.withAlpha(25)),
                    ),
                    child: const Column(
                      children: [
                        SkeletonBox.circle(size: 36),
                        SizedBox(height: 8),
                        SkeletonBox(width: 60, height: 13),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.grey.withAlpha(25)),
                    ),
                    child: const Column(
                      children: [
                        SkeletonBox.circle(size: 36),
                        SizedBox(height: 8),
                        SkeletonBox(width: 60, height: 13),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 22),
            const SkeletonBox(width: 140, height: 16, margin: EdgeInsets.only(bottom: 12)),
            ...List.generate(3, (index) => Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.grey.withAlpha(25)),
              ),
              child: const Row(
                children: [
                  Expanded(child: SkeletonBox(height: 14, width: double.infinity)),
                  SizedBox(width: 12),
                  SkeletonBox(width: 16, height: 16, borderRadius: 4),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }
}

/// Tab Skeleton View router: switches skeleton based on current active tab index
class PartnerTabSkeletonView extends StatelessWidget {
  final int tabIndex;

  const PartnerTabSkeletonView({super.key, required this.tabIndex});

  @override
  Widget build(BuildContext context) {
    Widget skeleton;

    switch (tabIndex) {
      case 0: // Home Tab
        skeleton = const PartnerDashboardHomeSkeleton();
        break;
      case 1: // Upcoming Appointments
      case 9: // Completed Appointments
      case 14: // Cancelled Appointments
      case 15: // Today's Bookings
        skeleton = const PartnerAppointmentsSkeleton();
        break;
      case 3: // OPD Clinic Contact
      case 4: // Pathology Lab Contact
      case 11: // Doctor Profile Contact
        skeleton = const PartnerFormProfileSkeleton();
        break;
      case 5: // Show Doctors Directory
        skeleton = const PartnerDoctorsSkeleton();
        break;
      case 6: // Show Tests Catalog
        skeleton = const PartnerTestsSkeleton();
        break;
      case 7: // Medical Card Access
        skeleton = const PartnerMedicalCardSkeleton();
        break;
      case 8: // Patient Lists / Inquiries
        skeleton = const PartnerPatientInquiriesSkeleton();
        break;
      case 10: // Help & Support
        skeleton = const PartnerHelpSkeleton();
        break;
      case 2: // Account Settings
      default:
        skeleton = const PartnerFormProfileSkeleton();
        break;
    }

    return Container(
      color: AppColors.background,
      child: skeleton,
    );
  }
}
