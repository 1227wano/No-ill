import 'package:flutter/material.dart';
import 'package:daum_postcode_search/daum_postcode_search.dart'; // 라이브러리 임포트
import 'package:webview_flutter/webview_flutter.dart';

class AddressSearchScreen extends StatefulWidget {
  const AddressSearchScreen({super.key});

  @override
  State<AddressSearchScreen> createState() => _AddressSearchScreenState();
}

class _AddressSearchScreenState extends State<AddressSearchScreen> {
  late WebViewController _controller;
  // ✅ 수정 1: 직접 정의했던 클래스를 지우고 라이브러리 클래스를 변수로 선언합니다.
  final DaumPostcodeSearch _daumPostcodeSearch = DaumPostcodeSearch();

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..addJavaScriptChannel(
        'DaumPostcodeJSChannel', // 1.0.0 버전 필수 채널명
        onMessageReceived: (JavaScriptMessage message) {
          // ✅ 수정 2: 라이브러리의 DataModel을 사용하여 데이터를 파싱합니다.
          try {
            final data = DataModel.fromRawJson(message.message);
            Navigator.pop(context, data);
          } catch (e) {
            print("주소 데이터 파싱 에러: $e");
          }
        },
      );
    _initServer();
  }

  Future<void> _initServer() async {
    // 로컬 서버를 실행하고 반환된 URL을 웹뷰에 로드합니다.
    final url = await _daumPostcodeSearch.launchServer();
    _controller.loadRequest(Uri.parse(url));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("주소 검색")),
      body: WebViewWidget(controller: _controller), // 웹뷰 표시
    );
  }
}

// ❌ 절대 여기에 class DaumPostcodeSearch {} 를 다시 만들지 마세요!
