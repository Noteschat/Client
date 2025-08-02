import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:noteschat/components/NewNote/NewNote.dart';
import 'package:noteschat/components/Note/NoteView.dart';
import 'package:noteschat/components/NotesSelect/NoteCard.dart';
import 'package:noteschat/dtos/Note.dart';
import 'package:noteschat/login.dart';

class NotesSelect extends StatefulWidget {
  final String chatId, host;
  const NotesSelect({super.key, required this.chatId, required this.host});

  @override
  State<NotesSelect> createState() => _NotesSelectState(host, chatId);
}

class _NotesSelectState extends State<NotesSelect> {
  List<AllNote> notes = [];
  List<String> tags = [];
  bool loadingNotes = true;

  _NotesSelectState(String host, String chatId) {
    fetch(host, chatId);
  }

  void fetch(String host, String chatId) async {
    List<Future> tasks = [];

    tasks.add(
      http
          .get(
            Uri.parse("http://$host/api/notes/storage/$chatId"),
            headers: headers,
          )
          .then((res) {
            if (res.statusCode == 200) {
              var tagsRes = jsonDecode(res.body)["tags"];
              setState(() {
                for (String tag in tagsRes) {
                  tags.add(tag);
                }
              });
              var notesRes = jsonDecode(res.body)["notes"];
              setState(() {
                for (var note in notesRes) {
                  notes.add(AllNote.fromJson(note));
                }

                loadingNotes = false;
              });
            } else {
              print(res.body);

              setState(() {
                loadingNotes = false;
              });

              showDialog(
                context: context,
                builder: (context) {
                  return AlertDialog(
                    title: Text("Getting Notes Failed"),
                    content: Text(
                      "It seems like we couldn't get your notes. Please try again later.",
                    ),
                    actions: [
                      FilledButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        child: Text("Ok"),
                      ),
                    ],
                  );
                },
              );
            }
          }),
    );

    await Future.wait(tasks);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surfaceBright,
        title: Text("Notes"),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: IconButton(
              onPressed: () async {
                AllNote? newNote = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder:
                        (context) => NewNoteView(
                          host: widget.host,
                          chatId: widget.chatId,
                        ),
                  ),
                );
                if (newNote != null) {
                  setState(() {
                    notes.add(newNote);
                  });

                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder:
                          (context) => NoteView(
                            chatId: widget.chatId,
                            host: widget.host,
                            allNote: newNote,
                          ),
                    ),
                  );
                }
              },
              icon: Icon(Icons.add),
            ),
          ),
        ],
      ),
      body:
          notes.length <= 0
              ? Center(
                child:
                    loadingNotes
                        ? Text("Loading Notes for this Chat")
                        : Text("No Notes in this Chat"),
              )
              : Column(
                children: [
                  for (var note in notes)
                    NoteCard(
                      note: note,
                      tags: tags,
                      removeNote: () {
                        setState(() {
                          notes.remove(note);
                        });
                      },
                      host: widget.host,
                      chatId: widget.chatId,
                    ),
                ],
              ),
    );
  }
}
