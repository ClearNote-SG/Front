import 'package:flutter/material.dart';

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
                      // 저장 기능 구현
                      print("회의록이 저장되었습니다.");
                    },
                    child: Text('저장'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      // 녹음 재생 기능 구현
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
