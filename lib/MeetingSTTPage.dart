import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

import 'MeetingSummaryPage.dart';
import 'RecordingDetailPage.dart';

class MeetingSTTPage extends StatefulWidget {
  final int meetingId;
  final String meetingTitle;

  MeetingSTTPage({required this.meetingId, required this.meetingTitle});

  @override
  _MeetingSTTPageState createState() => _MeetingSTTPageState();
}

class _MeetingSTTPageState extends State<MeetingSTTPage> {
  String _meetingText = ''; // 서버에서 받은 회의 텍스트
  Uint8List? _audioBytes; // 서버에서 받은 오디오 바이트 데이터
  bool _isLoading = true; // 로딩 상태
  bool _isPlaying = false; // 재생 상태
  final FlutterSoundPlayer _audioPlayer = FlutterSoundPlayer();
  XFile? _selectedImage;

  @override
  void initState() {
    super.initState();
    _audioPlayer.openPlayer(); // Flutter Sound 플레이어 초기화
    _fetchMeetingSTTData(); // STT 데이터 요청
  }

  @override
  void dispose() {
    _audioPlayer.closePlayer(); // 플레이어 종료
    super.dispose();
  }

  Future<void> _fetchMeetingSTTData() async {
    try {
      final String apiUrl = "http://10.0.2.2:8080/stt"; // 백엔드 URL
      /*final response = await http.post(
        Uri.parse(apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'meetingId': widget.meetingId.toString()}), // ID 전송
      );*/
      var request = http.MultipartRequest('POST', Uri.parse(apiUrl))
        ..fields['meetingId'] = widget.meetingId.toString(); // 회의 ID 추가

      var response = await request.send();

      if (response.statusCode == 200) {
        String responseBody = await response.stream.bytesToString();
        Map<String, dynamic> data = json.decode(responseBody);
        final String base64Audio = data['meetingAudio']; // base64 인코딩된 바이트 데이터
        final String text = data['meetingContent'] ?? '텍스트가 없습니다.';

        // 바이트 데이터 디코딩
        final Uint8List audioBytes = base64.decode(base64Audio);

        setState(() {
          _meetingText = text;
          _audioBytes = audioBytes; // 바이트 데이터를 상태에 저장
          _isLoading = false; // 로딩 완료
        });
      } else {
        print("STT 요청 실패: ${response.statusCode}");
        setState(() {
          _isLoading = false; // 로딩 완료로 변경
        });
      }
    } catch (e) {
      print("오류 발생: $e");
      setState(() {
        _isLoading = false; // 로딩 완료로 변경
      });
    }
  }

  Future<void> _playAudio() async {
    if (_isPlaying) {
      await _audioPlayer.stopPlayer(); // 재생 중이면 정지
    } else if (_audioBytes != null) {
      await _audioPlayer.startPlayer(
        fromDataBuffer: _audioBytes, // 바이트 데이터를 직접 재생
        codec: Codec.mp3, // MP3 형식으로 재생
        whenFinished: () {
          setState(() {
            _isPlaying = false; // 재생 종료 시 상태 업데이트
          });
        },
      );
      setState(() {
        _isPlaying = true; // 재생 상태 변경
      });
    }
  }
/*
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('회의록 STT'),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator()) // 로딩 중일 때
          : Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '회의 텍스트:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Expanded(
              child: SingleChildScrollView(
                child: Text(
                  _meetingText,
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ),
            SizedBox(height: 20),
            Center(
              child: ElevatedButton(
                onPressed: _audioBytes != null ? _playAudio : null,
                child: Text(_isPlaying ? '정지' : '음성 재생'),
              ),
            ),
          ],
        ),
      ),
    );
  }
 */
  // 요약 페이지로 이동
  /*
  void _goToSummaryPage() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => RecordingDetailPage(id: widget.meetingId, recordingDate: "")),
    );
  }*/
  // 이미지 선택
  // 이미지 선택
  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _selectedImage = pickedFile; // 선택된 이미지 저장
      });

      // 이미지가 선택되면 다음 페이지로 이동
      _goToSummaryPage();
    }
  }

  // 회의록 양식 선택 및 요약 페이지로 이동
  void _goToSummaryPage() {
    if (_selectedImage != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => MeetingSummaryPage(
            meetingId: widget.meetingId,
            meetingTitle: widget.meetingTitle,
            selectedImage: _selectedImage!, // 선택된 이미지와 회의록 ID를 전달
          ),
        ),
      );
    } else {
      // 이미지가 선택되지 않은 경우 알림
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("이미지를 선택해 주세요")),
      );
    }
  }

  /*@override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
            widget.meetingTitle, // 전달받은 회의 제목
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator()) // 로딩 중일 때
          : Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 회의 제목 표시
            Text(
              "회의 텍스트", // 전달받은 회의 제목
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            // 회의 텍스트 박스 (스크롤 가능)
            Expanded(
              child: SingleChildScrollView(
                child: Text(
                  _meetingText,
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ),
            SizedBox(height: 20),
            // 음성 재생 버튼
            // 회의록 양식 선택 및 요약 버튼
            Center(

              child: ElevatedButton(
                onPressed: _pickImage, // 이미지 선택
                child: Text('회의록 양식 선택 및 요약'),
              ),
            ),
            SizedBox(height: 20),
            // 선택된 이미지 미리보기 (이미지가 선택되었을 때만 표시)
            if (_selectedImage != null)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Image.file(
                  File(_selectedImage!.path),
                  height: 150, // 이미지 크기 조정
                  width: 150,
                  fit: BoxFit.cover,
                ),
              ),
            // 요약 페이지로 가는 버튼
            Center(
              child: ElevatedButton(
                onPressed: _goToSummaryPage,
                child: Text('양식 및 요약 확인'),
              ),
            ),
          ],
        ),
      ),
    );
  }*/

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.meetingTitle, // 전달받은 회의 제목
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator()) // 로딩 중일 때
          : Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 회의 제목 표시
            Text(
              "회의 텍스트", // 전달받은 회의 제목
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            // 회의 텍스트 박스 (스크롤 가능)
            Expanded(
              child: SingleChildScrollView(
                child: Text(
                  _meetingText,
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ),
            SizedBox(height: 20),
            // 음성 재생 버튼
            Center(
              child: ElevatedButton(
                onPressed: _audioBytes != null ? _playAudio : null,
                child: Text(_isPlaying ? '정지' : '음성 재생'),
              ),
            ),
            SizedBox(height: 20),
            // 회의록 양식 선택 및 요약 버튼
            Center(
              child: ElevatedButton(
                onPressed: _pickImage, // 이미지 선택
                child: Text('회의록 양식 선택 및 요약'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
