import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:noteschat/dtos/Note.dart';
import 'package:noteschat/login.dart';

class NoteView extends StatefulWidget {
  final String host;
  final String chatId;
  final AllNote allNote;
  const NoteView({super.key, required this.allNote, required this.chatId, required this.host});

  @override
  State<NoteView> createState() => _NoteViewState(allNote, chatId, host);
}

class _NoteViewState extends State<NoteView> {
  late Note note;
  bool loadingNote = true;

  _NoteViewState(AllNote allNote, String chatId, String host) {
    fetch(allNote, chatId, host);
  }

  void fetch(AllNote allNote, String chatId, String host) async {
    List<Future> tasks = [];

    tasks.add(http.get(Uri.parse("http://$host/api/notes/storage/$chatId/${allNote.id}"), headers: headers).then((res) {
      if(res.statusCode == 200) {
        var noteRes = jsonDecode(res.body);
        setState(() {
          note = Note.fromJson(noteRes);

          loadingNote = false;
        });
      } else {
        setState(() {
          loadingNote = false;
        });

        showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: Text("Getting Note Failed"),
              content: Text("It seems like we couldn't get your note. Please try again later."),
              actions: [
                FilledButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: Text("Ok")
                )
              ],
            );
          }
        );
      }
    }));

    await Future.wait(tasks);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surfaceBright,
        title: loadingNote ? Text(widget.allNote.name) : Text(note.name),
      ),
      body: loadingNote ? Text("Loading Note...") : Text(note.content),
    );
  }
}