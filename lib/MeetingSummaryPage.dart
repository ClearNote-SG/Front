import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

import 'main.dart';

class MeetingSummaryPage extends StatefulWidget {
  final int meetingId;
  final String meetingTitle;
  final XFile selectedImage; // 선택된 이미지

  MeetingSummaryPage({
    required this.meetingId,
    required this.meetingTitle,
    required this.selectedImage,
  });

  @override
  _MeetingSummaryPageState createState() => _MeetingSummaryPageState();
}

class _MeetingSummaryPageState extends State<MeetingSummaryPage> {
  String _meetingSummary = ''; // 서버에서 받은 요약 내용
  String _fetchedMeetingTitle = ''; // 서버에서 받은 회의 제목
  bool _isLoading = true; // 로딩 상태

  @override
  void initState() {
    super.initState();
    _fetchMeetingSummary(); // 백엔드에서 회의록 요약 요청
  }

  Future<void> _fetchMeetingSummary() async {
    try {
      final String apiUrl = "http://10.0.2.2:8080/summarize"; // 요약 API URL

      var request = http.MultipartRequest('POST', Uri.parse(apiUrl))
        ..fields['meetingId'] = widget.meetingId.toString(); // 회의 ID 추가
      var file = await http.MultipartFile.fromPath('meetingTemplate', widget.selectedImage.path);
      request.files.add(file); // 선택된 이미지를 추가

      var response = await request.send();

      if (response.statusCode == 200) {
        String responseBody = await response.stream.bytesToString();
        Map<String, dynamic> data = json.decode(responseBody);
        final String summary = data['meetingSummary'] ?? '회의록 요약이 없습니다.';
        final String title = data['meetingTitle'] ?? '회의 제목을 불러오지 못했습니다.';

        setState(() {
          _meetingSummary = summary;
          _fetchedMeetingTitle = title;
          _isLoading = false; // 로딩 완료
        });
      } else {
        print("요약 요청 실패: ${response.statusCode}");
        setState(() {
          _isLoading = false; // 로딩 완료
        });
      }
    } catch (e) {
      print("오류 발생: $e");
      setState(() {
        _isLoading = false; // 로딩 완료
      });
    }
  }

  // 처음 화면으로 돌아가기
  void _goBackToHome() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => VoiceRecordingApp()), // YourHomePage는 맨 처음 화면으로 가는 페이지
          (route) => false, // 이전 경로를 모두 제거하고 새로운 화면으로 이동
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.meetingTitle, // 전달받은 회의 제목
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),),
        actions: [
          IconButton(
            icon: Icon(Icons.home),
            onPressed: _goBackToHome, // 처음 화면으로 돌아가는 버튼
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator()) // 로딩 중일 때
          : Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 회의 제목 표시 (박스 없이 그냥 텍스트로 표시)
            Text(
              "회의 제목: ${_fetchedMeetingTitle}",
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),
            // 회의 요약 표시
            Text(
              "회의 요약:",
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            // 회의 요약을 위한 스크롤 박스
            Container(
              padding: EdgeInsets.all(8.0),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(8),
              ),
              height: 500, // 요약 박스 높이 설정
              child: SingleChildScrollView(
                child: Text(
                  _meetingSummary,
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}