// lib/screens/accident/event_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../models/pet_model.dart';

class EventDetailScreen extends StatelessWidget {
  final String title;
  final String body;
  final String? imageUrl;
  final PetModel pet;

  const EventDetailScreen({
    super.key,
    required this.title,
    required this.body,
    required this.pet,
    this.imageUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("${pet.careName} 어르신 알림")),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 🖼 이미지를 화면 너비에 꽉 차게 표시
            if (imageUrl != null)
              Image.network(
                imageUrl!,
                width: 1.sw,
                height: 0.4.sh,
                fit: BoxFit.cover,
                errorBuilder: (context, e, s) => Container(
                  height: 200.h,
                  color: Colors.grey[200],
                  child: const Icon(Icons.broken_image, size: 50),
                ),
              ),

            Padding(
              padding: EdgeInsets.all(20.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 22.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.redAccent,
                    ),
                  ),
                  SizedBox(height: 12.h),
                  Text(body, style: TextStyle(fontSize: 18.sp, height: 1.5)),
                  SizedBox(height: 40.h),
                  // 조치 버튼
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      minimumSize: Size(double.infinity, 50.h),
                      backgroundColor: const Color(0xFF2C3E50),
                    ),
                    child: const Text(
                      "확인 완료",
                      style: TextStyle(color: Colors.white),
                    ),
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
