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
  final TextEditingController _noteEditController = TextEditingController();

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
          _noteEditController.text = note.content;

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

  void updateNote() async {
    setState(() {
      note = Note(
        id: note.id,
        name: note.name, 
        chatId: note.chatId, 
        content: _noteEditController.text
      );
    });

    var change = http.put(
      Uri.parse("http://${widget.host}/api/notes/storage/${widget.chatId}/${note.id}"),
      headers: headers,
      body: jsonEncode(note)
    );

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Saving Note"),
          content: Text("Saving Note..."),
        );
      },
    );

    var res = (await Future.wait([change]))[0];
    Navigator.pop(context);
    if(res.statusCode != 200) {
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text("Saving Note Failed"),
            content: Text("It seems like we couldn't save your note. Please try again later."),
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surfaceBright,
        title: loadingNote ? Text(widget.allNote.name) : Text(note.name),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: IconButton(
              onPressed: loadingNote || note.content == _noteEditController.text ? null : () async {
                updateNote();
              },
              icon: Icon(Icons.save_outlined),
            ),
          ),
        ],
      ),
      body: loadingNote ? Center(
        child: Text("Loading Note...")
       ) : Padding(
        padding: EdgeInsets.all(8.0),
        child: TextField(
          controller: _noteEditController,
          minLines: null,
          maxLines: null,
          expands: true,
          textInputAction: TextInputAction.newline,
          keyboardType: TextInputType.multiline,
          decoration: const InputDecoration(
            border: InputBorder.none,
          ),
          style: TextStyle(
            fontSize: 14.0,
          ),
          onChanged: (value) {
            setState(() {});
          },
        )
      ),
    );
  }
}