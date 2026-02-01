import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class CustomCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final Color? backgroundColor;
  final double? borderRadius;
  final VoidCallback? onTap;
  final bool showShadow;
  final bool showBorder;

  const CustomCard({
    super.key,
    required this.child,
    this.padding,
    this.backgroundColor,
    this.borderRadius,
    this.onTap,
    this.showShadow = true,
    this.showBorder = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: backgroundColor ?? Colors.white.withOpacity(0.9), // 약간 투명하게
        borderRadius: BorderRadius.circular(borderRadius ?? 24.r),
        border: Border.all(
          color: Colors.white.withOpacity(0.5), // 유리 테두리 효과
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03), // 아주 은은한 그림자
            blurRadius: 40,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Material(
        color: backgroundColor ?? Colors.white,
        borderRadius: BorderRadius.circular(borderRadius ?? 24.r),
        // ✅ 미세한 테두리로 경계선을 선명하게 (Border)
        shape: showBorder
            ? RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(borderRadius ?? 24.r),
                side: BorderSide(
                  color: Colors.black.withOpacity(0.05),
                  width: 1,
                ),
              )
            : null,
        clipBehavior: Clip.antiAlias,
        child: onTap != null
            ? InkWell(
                // ✅ onTap이 있을 때만 InkWell로 감쌉니다.
                onTap: onTap,
                child: Padding(
                  padding: padding ?? EdgeInsets.all(20.w),
                  child: child,
                ),
              )
            : Padding(
                // ✅ onTap이 없으면 그냥 Padding만 둡니다.
                padding: padding ?? EdgeInsets.all(20.w),
                child: child,
              ),
      ),
    );
  }
}
