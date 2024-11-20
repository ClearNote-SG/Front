import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:http/http.dart' as http;

class RecordingDetailPage extends StatefulWidget {
  final String filePath;
  final String recordingDate;

  RecordingDetailPage({required this.filePath, required this.recordingDate});

  @override
  _RecordingDetailPageState createState() => _RecordingDetailPageState();
}

class _RecordingDetailPageState extends State<RecordingDetailPage> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _mainContentController = TextEditingController();
  final TextEditingController _conclusionController = TextEditingController();

  // FlutterSoundPlayer 인스턴스 생성
  FlutterSoundPlayer _audioPlayer = FlutterSoundPlayer();
  bool _isPlaying = false; // 음성 재생 여부 체크

  @override
  void initState() {
    super.initState();
    // _audioPlayer를 사용하기 전에 준비 작업을 해줍니다.
    _audioPlayer.openPlayer();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _mainContentController.dispose();
    _conclusionController.dispose();
    _audioPlayer.closePlayer(); // 플레이어 종료
    super.dispose();
  }

  Future<void> _sendAudioFileAndPopulateFields() async {
    try {
      const String apiUrl = "http://10.0.2.2:8000/meeting"; // 서버 URL

      // 오디오 파일을 읽어들입니다.
      File audioFile = File(widget.filePath);
      List<int> fileBytes = await audioFile.readAsBytes();

      // 서버로 POST 요청을 보냅니다.
      var response = await http.post(
        Uri.parse(apiUrl),
        headers: {"Content-Type": "application/octet-stream"},
        body: fileBytes,
      );

      // 서버 응답을 처리합니다.
      if (response.statusCode == 200) {
        Map<String, dynamic> responseData = json.decode(response.body);
        setState(() {
          // 서버로부터 받은 데이터를 텍스트 필드에 채웁니다.
          _titleController.text = responseData['title'] ?? '';
          _mainContentController.text = responseData['content'] ?? '';
          _conclusionController.text = responseData['summary'] ?? '';
        });
        print("서버 응답 성공: ${responseData}");
      } else {
        print("POST 요청 실패: ${response.statusCode}");
      }
    } catch (e) {
      print("오류 발생: $e");
    }
  }

  // 녹음 재생 함수
  Future<void> _playRecording() async {
    if (_isPlaying) {
      await _audioPlayer.stopPlayer(); // 재생 중이면 정지
    } else {
      await _audioPlayer.startPlayer(
        fromURI: widget.filePath, // 녹음 파일 경로를 지정
        whenFinished: () {
          setState(() {
            _isPlaying = false; // 재생 종료 시 상태 업데이트
          });
        },
      );
      setState(() {
        _isPlaying = true; // 재생 중 상태로 변경
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('회의록 상세 정보'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '회의 날짜: ${widget.recordingDate}',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 20),
              TextField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: '회의 제목',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 20),
              TextField(
                controller: _mainContentController,
                decoration: InputDecoration(
                  labelText: '주요 내용',
                  border: OutlineInputBorder(),
                ),
                maxLines: 6,
              ),
              SizedBox(height: 20),
              TextField(
                controller: _conclusionController,
                decoration: InputDecoration(
                  labelText: '결론',
                  border: OutlineInputBorder(),
                ),
                maxLines: 4,
              ),
              SizedBox(height: 30),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      // 제목 반환
                      Navigator.pop(context, _titleController.text);
                    },
                    child: Text('저장'),
                  ),
                  ElevatedButton(
                    onPressed: _playRecording, // 녹음 재생 버튼
                    child: Text(_isPlaying ? '정지' : '녹음 재생'),
                  ),
                  ElevatedButton(
                    onPressed: _sendAudioFileAndPopulateFields, // 파일 전송 버튼
                    child: Text('파일 전송'),
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
