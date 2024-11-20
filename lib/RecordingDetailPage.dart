import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
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

  @override
  void dispose() {
    _titleController.dispose();
    _mainContentController.dispose();
    _conclusionController.dispose();
    super.dispose();
  }

  Future<void> _sendAudioFileAndPopulateFields() async {
    try {
      const String apiUrl = "http://10.0.2.2:8000/meeting";

      File audioFile = File(widget.filePath);
      List<int> fileBytes = await audioFile.readAsBytes();

      var response = await http.post(
        Uri.parse(apiUrl),
        headers: {"Content-Type": "application/octet-stream"},
        body: fileBytes,
      );

      if (response.statusCode == 200) {
        Map<String, dynamic> responseData = json.decode(response.body);
        setState(() {
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
                    onPressed: () {
                      print("녹음을 재생합니다: ${widget.filePath}");
                    },
                    child: Text('녹음 재생'),
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
//