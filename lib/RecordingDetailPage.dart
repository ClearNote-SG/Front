import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart'; // MediaType 추가
import 'package:image_picker/image_picker.dart'; // 이미지 선택

class RecordingDetailPage extends StatefulWidget {
  final int id;
  final String recordingDate;
  final XFile selectedImage;

  RecordingDetailPage({required this.id, required this.recordingDate, required this.selectedImage});

  @override
  _RecordingDetailPageState createState() => _RecordingDetailPageState();
}

class _RecordingDetailPageState extends State<RecordingDetailPage> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _summaryController = TextEditingController();
  final TextEditingController _mainContentController = TextEditingController();

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
    _summaryController.dispose();
    _mainContentController.dispose();
    _audioPlayer.closePlayer(); // 플레이어 종료
    super.dispose();
  }

  Future<void> _sendAudioFileAndPopulateFields({String? imagePath}) async {
    /*try {
      const String apiUrl = "http://10.0.2.2:8000/meeting"; // 서버 URL

      // 오디오 파일 준비
      File audioFile = File(widget.filePath);

      // Multipart 요청 생성
      var request = http.MultipartRequest('POST', Uri.parse(apiUrl))
        ..files.add(await http.MultipartFile.fromPath(
          'meetingAudio', // 서버에서 요구하는 파일 이름
          audioFile.path,
          contentType: MediaType('audio', 'mp3'), // mp3 파일 타입
        ));

      // 이미지 파일이 있으면 추가
      if (imagePath != null) {
        File imageFile = File(imagePath);
        request.files.add(await http.MultipartFile.fromPath(
          'meetingTemplate', // 서버에서 요구하는 파일 이름
          imageFile.path,
          contentType: MediaType('image', 'jpeg'), // jpg 파일 타입
        ));
      }

      // 서버로 요청 전송
      var response = await request.send();

      if (response.statusCode == 200) {
        // 서버 응답 읽기
        String responseBody = await response.stream.bytesToString();
        Map<String, dynamic> responseData = json.decode(responseBody);

        setState(() {
          // 서버로부터 받은 데이터를 제목과 주요 내용 텍스트 필드에 채웁니다.
          _titleController.text = responseData['title'] ?? '';
          _mainContentController.text = responseData['content'] ?? '';
        });
        print("서버 응답 성공: $responseData");
      } else {
        print("POST 요청 실패: ${response.statusCode}");
      }
    } catch (e) {
      print("오류 발생: $e");
    }*/
    try {
      const String apiUrl = "http://10.0.2.2:8080/summarize"; // 서버 URL

      var request = http.MultipartRequest('POST', Uri.parse(apiUrl))
        ..fields['meetingId'] = widget.id.toString(); // 회의 ID 추가

      // 이미지 파일 추가
      if (imagePath != null) {
        File imageFile = File(imagePath);
        request.files.add(await http.MultipartFile.fromPath(
          'meetingTemplate',
          imageFile.path,
          contentType: MediaType('image', 'jpeg'),
        ));
      }

      // 요청 전송
      var response = await request.send();

      if (response.statusCode == 200) {
        // 서버 응답 읽기
        String responseBody = await response.stream.bytesToString();
        Map<String, dynamic> responseData = json.decode(responseBody);

        setState(() {
          _titleController.text = responseData['meetingTitle'] ?? '제목 없음';
          _summaryController.text = responseData['meetingSummary'] ?? '요약 없음';
          _mainContentController.text = responseData['meetingContent'] ?? '내용 없음';
        });
        print("서버 응답 성공: $responseData");
      } else {
        print("POST 요청 실패: ${response.statusCode}");
      }
    } catch (e) {
      print("오류 발생: $e");
    }

  }

  // 녹음 재생 함수
  /*Future<void> _playRecording() async {
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
  }*/

  // 이미지 선택 및 전송
  Future<void> _pickImageAndSendFile() async {
    final ImagePicker picker = ImagePicker();
    final XFile? pickedImage = await picker.pickImage(source: ImageSource.gallery);

    if (pickedImage != null) {
      await _sendAudioFileAndPopulateFields(imagePath: pickedImage.path);
    } else {
      print("이미지가 선택되지 않았습니다.");
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
                controller: _summaryController,
                decoration: InputDecoration(
                  labelText: '회의 요약',
                  border: OutlineInputBorder(),
                ),
                maxLines: 4, // 여러 줄 입력 가능
              ),
              SizedBox(height: 20),
              TextField(
                controller: _mainContentController,
                decoration: InputDecoration(
                  labelText: '회의 내용',
                  border: OutlineInputBorder(),
                ),
                maxLines: 6,
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
                    onPressed: _pickImageAndSendFile, // 이미지 선택 및 파일 전송
                    child: Text('이미지 추가 & 파일 전송'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

/*
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
                    onPressed: _pickImageAndSendFile, // 이미지 선택 및 파일 전송
                    child: Text('이미지 추가 & 파일 전송'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }*/
}

