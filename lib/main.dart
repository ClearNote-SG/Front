import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'dart:io';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:table_calendar/table_calendar.dart';

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
  Map<String, List<String>> _recordingsByDate = {}; // 날짜별 녹음 파일

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
    final filePath = '${directory.path}/meeting_record_${DateTime.now().millisecondsSinceEpoch}.aac';

    await _recorder.startRecorder(toFile: filePath);
    setState(() {
      _isRecording = true;
      _recordedFilePath = filePath;
      _recordingDate = DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());
    });
  }

  void _stopRecording() async {
    await _recorder.stopRecorder();
    setState(() {
      _isRecording = false;
    });
    _loadRecordedFiles();
  }

  void _loadRecordedFiles() async {
    final directory = await getApplicationDocumentsDirectory();
    final List<FileSystemEntity> files = Directory(directory.path).listSync();
    setState(() {
      _recordedFiles = files
          .where((file) => file.path.endsWith('.aac'))
          .map((file) => file.path)
          .toList();

      _recordingsByDate.clear(); // 날짜별 녹음 파일 초기화
      for (var filePath in _recordedFiles) {
        String dateKey = DateFormat('yyyy-MM-dd').format(File(filePath).lastModifiedSync());
        if (!_recordingsByDate.containsKey(dateKey)) {
          _recordingsByDate[dateKey] = [];
        }
        _recordingsByDate[dateKey]!.add(filePath);
      }
    });
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
              });
            },
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _recordingsByDate[_selectedDay.toString().split(' ')[0]]?.length ?? 0,
              itemBuilder: (context, index) {
                final filePath = _recordingsByDate[_selectedDay.toString().split(' ')[0]]![index];

                return ListTile(
                  title: Text(
                    'Recording: ${filePath.split('/').last}',
                    style: TextStyle(fontSize: 16),
                    overflow: TextOverflow.ellipsis,
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => RecordingDetailPage(
                          filePath: filePath,
                          recordingDate: _selectedDay.toString().split(' ')[0],
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

  void _playRecording() {
    final player = FlutterSoundPlayer();
    player.openPlayer().then((_) {
      player.startPlayer(fromURI: widget.filePath).then((_) {
        // Optionally handle when playback is done
      });
    });
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
                    onPressed: _playRecording,
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
