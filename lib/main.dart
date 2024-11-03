import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'dart:io';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:table_calendar/table_calendar.dart'; // 달력 패키지 추가

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
  final FlutterSoundPlayer _player = FlutterSoundPlayer();
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
    await _player.openPlayer();
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
    print('Recorded file path: $_recordedFilePath');
    print('Recording date: $_recordingDate');
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

  void _playRecording(String path) async {
    await _player.startPlayer(fromURI: path);
  }

  @override
  void dispose() {
    _recorder.closeRecorder();
    _player.closePlayer();
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
            child: ListView(
              children: _recordingsByDate[_selectedDay.toString().split(' ')[0]]?.map((filePath) {
                return ListTile(
                  title: Text('Recording: ${filePath.split('/').last}'),
                  onTap: () => _playRecording(filePath),
                );
              }).toList() ?? [
                ListTile(title: Text('No recordings for this date.')),
              ],
            ),
          ),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _isRecording ? 'Recording...' : '회의 녹음 시작',
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
                    'Recorded on: $_recordingDate',
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