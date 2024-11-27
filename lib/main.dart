import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'dart:io';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:table_calendar/table_calendar.dart';

// RecordingDetailPage 위젯을 import 합니다.
import 'MeetingSTTPage.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart'; // MediaType 추가

void main() {
  runApp(MaterialApp(
    home: VoiceRecordingApp(),
  ));
}

class VoiceRecordingApp extends StatefulWidget {
  @override
  _VoiceRecordingAppState createState() => _VoiceRecordingAppState();
}

class _VoiceRecordingAppState extends State<VoiceRecordingApp> {
  final FlutterSoundRecorder _recorder = FlutterSoundRecorder();
  bool _isRecording = false;
  String _recordedFilePath = '';
  String _recordingDate = '';
  List<String> _recordedFiles = [];
  List<int> _recordedIds = [];
  DateTime _selectedDay = DateTime.now();

  @override
  void initState() {
    super.initState();
    _initializeRecorder();
    _loadRecordedFiles();
  }

  void _initializeRecorder() async {
    await requestMicrophonePermission();
    await _recorder.openRecorder();
  }

  Future<void> requestMicrophonePermission() async {
    var status = await Permission.microphone.status;
    if (!status.isGranted) {
      await Permission.microphone.request();
    }
  }

  void _startRecording() async {
    final directory = await getApplicationDocumentsDirectory();
    final filePath =
        '${directory.path}/meeting_record_${DateTime.now().millisecondsSinceEpoch}.aac';

    await _recorder.startRecorder(
        toFile: filePath
    );
    setState(() {
      _isRecording = true;
      _recordedFilePath = filePath;
      _recordingDate =
          DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());
    });
  }

  void _stopRecording() async {
    await _recorder.stopRecorder();
    setState(() {
      _isRecording = false;
    });
    _loadRecordedFiles();

    // 녹음이 완료되면 백엔드에 업로드하는 함수 호출
    _uploadRecording();
  }

  Future<void> _loadRecordedFiles() async {
    try {
      final selectedDate = DateFormat('yyyy-MM-dd').format(_selectedDay); // 날짜 포맷 (yyyy-MM-dd)
      final String apiUrl = "http://10.0.2.2:8080/meeting/meetingByDate/$selectedDate"; // 서버의 날짜별 회의록 요청 API

      print("API 요청 URL: $apiUrl"); // 요청 URL을 출력해서 확인

      // 백엔드에 GET 요청 보내기
      final response = await http.get(Uri.parse(apiUrl));

      // 응답 상태 출력
      print("서버 응답 상태 코드: ${response.statusCode}");
      print("서버 응답 바디: ${response.body}"); // 응답 바디를 출력하여 어떤 데이터가 왔는지 확인

      if (response.statusCode == 200) {
        final decodedBody = utf8.decode(response.bodyBytes);
        final Map<String, dynamic> meetingData = json.decode(decodedBody); // 서버 응답 데이터
        final List<String> titles = [];
        final List<int> ids = [];

        int i=1;
        // 서버에서 받은 데이터에서 제목만 추출
        meetingData.forEach((key, value) {
          for (var meeting in value) {
            titles.add(meeting['title'] ?? selectedDate.toString() + "__" +i.toString());
            ids.add(meeting['id']);
            i++;
          }
        });

        setState(() {
          _recordedFiles = titles; // 제목만 리스트에 저장
          _recordedIds = ids;
          print("저장된 제목 리스트: $_recordedFiles");
        });
      } else {
        print("서버 응답 실패: ${response.statusCode}");
      }
    } catch (e) {
      print("오류 발생: $e");
    }
  }

  Future<void> _uploadRecording() async {
    try {
      final uri = Uri.parse("http://10.0.2.2:8080/meeting");  // 백엔드 업로드 URL
      final request = http.MultipartRequest('POST', uri);

      // 파일을 추가합니다.
      final file = File(_recordedFilePath);
      final fileBytes = await file.readAsBytes();
      final multipartFile = http.MultipartFile.fromBytes(
        'voiceFile',  // 서버에서 받을 필드명 (파일을 받을 필드명)
        fileBytes,
        filename: 'meeting_record.aac',  // 파일 이름
        contentType: MediaType('audio', 'aac'),  // 파일 MIME 타입
      );

      request.files.add(multipartFile);

      // 서버에 파일 전송
      final response = await request.send();

      if (response.statusCode == 200) {
        print("회의 녹음 업로드 성공!");
      } else {
        print("회의 녹음 업로드 실패: ${response.statusCode}");
      }
    } catch (e) {
      print("파일 업로드 오류: $e");
    }
  }

  @override
  void dispose() {
    _recorder.closeRecorder();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('클리어노트'),
      ),
      body: Column(
        children: [
          TableCalendar(
            firstDay: DateTime.utc(2020, 1, 1),
            lastDay: DateTime.utc(2030, 12, 31),
            focusedDay: _selectedDay,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _loadRecordedFiles();  // 날짜 선택 시 회의록 로드
              });
            },
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _recordedFiles.length,
              itemBuilder: (context, index) {
                final title =  _recordedFiles[index];

                return ListTile(
                  title: Text(
                    title,  // 제목 표시
                    style: TextStyle(fontSize: 16),
                    overflow: TextOverflow.ellipsis,
                  ),
                  onTap: () {
                    // RecordingDetailPage로 이동
                    Navigator.push(
                      context,
                        MaterialPageRoute(
                        builder: (context) => MeetingSTTPage(
                          meetingId: _recordedIds[index],
                          meetingTitle: _recordedFiles[index],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _isRecording ? '녹음 중...' : '회의 녹음 시작',
                  style: TextStyle(fontSize: 20, color: Colors.blueAccent),
                ),
                SizedBox(height: 20),
                FloatingActionButton(
                  onPressed: _isRecording ? _stopRecording : _startRecording,
                  backgroundColor: _isRecording ? Colors.red : Colors.green,
                  child: Icon(_isRecording ? Icons.stop : Icons.mic),
                ),
                SizedBox(height: 20),
                if (_recordingDate.isNotEmpty)
                  Text(
                    '가장 최신 회의파일: $_recordingDate',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
//yongug medium push 2
