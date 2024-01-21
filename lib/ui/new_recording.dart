import 'package:flutter/material.dart';
import 'package:record/record.dart';
import 'package:just_audio/just_audio.dart';
import 'package:localstorage/localstorage.dart';
import 'package:http/http.dart' as http;
import 'dart:html' as html;

class NewRecording extends StatefulWidget {
  @override
  _NewRecordingState createState() => _NewRecordingState();
}

class _NewRecordingState extends State<NewRecording> {
  final TextEditingController _titleController = TextEditingController();
  final record = AudioRecorder();
  final LocalStorage storage = LocalStorage('soundboard.json');

  bool isRecording = false;
  bool hasRecorded = false;
  String? audioPath;

  @override
  void initState() {
    super.initState();
    record.hasPermission();
    setupStorage();
  }

  void setupStorage() async {
    var value = storage.getItem('sounds');
    if (value == null) {
      print('setting up storage');
      storage.setItem('sounds', []);
    }
    print(storage.getItem('sounds'));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('New Recording'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Padding(
              padding: EdgeInsets.all(8.0),
              child: TextField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: 'Title',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                !isRecording
                    ? ElevatedButton.icon(
                        onPressed: () {
                          setState(() {
                            isRecording = true;
                            audioPath = null;
                          });
                          record.start(const RecordConfig(encoder: AudioEncoder.wav), path: "test.wav");
                        },
                        icon: Icon(Icons.mic),
                        label: Text('Record'),
                      )
                    : SizedBox(),
                isRecording && audioPath == null
                    ? ElevatedButton.icon(
                        onPressed: () async {
                          final path = await record.stop();
                          setState(() {
                            isRecording = false;
                            hasRecorded = true;
                            audioPath = path;
                          });
                        },
                        icon: Icon(Icons.stop),
                        label: Text('Stop'),
                      )
                    : SizedBox(),
                hasRecorded && audioPath != null
                    ? ElevatedButton.icon(
                        onPressed: () async {
                          final player = AudioPlayer();
                          await player.setUrl(audioPath!);
                          player.play();
                        },
                        icon: Icon(Icons.play_arrow),
                        label: Text('Play'),
                      )
                    : SizedBox(),
                hasRecorded && audioPath != null
                    ? ElevatedButton.icon(
                        onPressed: () async {
                          final response = await http.get(Uri.parse(audioPath!));
                          final data = Uri.dataFromBytes(response.bodyBytes, mimeType: 'audio/wav').toString();

                          var value = storage.getItem('sounds');
                          final sounds = value as List;
                          sounds.add({'audio': data, 'title': _titleController.text});
                          storage.setItem('sounds', sounds);

                          Navigator.of(context).pop();
                        },
                        icon: Icon(Icons.save),
                        label: Text('Save'),
                      )
                    : SizedBox(),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
