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

String resetNotesFilterValue = "Filter by tag...";

class _NotesSelectState extends State<NotesSelect> {
  List<AllNote> notes = [];
  List<String> tags = [];
  bool loadingNotes = true;

  String selectedTag = "";

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

  List<DropdownMenuItem<String>> tagOptions() {
    List<String> options = [];
    options.add(resetNotesFilterValue);
    options.addAll(tags);
    var mapped =
        options.map<DropdownMenuItem<String>>((tag) {
          return DropdownMenuItem<String>(
            key: Key(tag),
            value: tag,
            child: Text(tag),
          );
        }).toList();
    return mapped;
  }

  List<AllNote> filteredNotes() {
    return notes.where((note) {
      return selectedTag.isEmpty || note.tags.contains(selectedTag);
    }).toList();
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
              : Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    tags.isNotEmpty
                        ? FractionallySizedBox(
                          widthFactor: 1,
                          child: DropdownButton<String>(
                            value:
                                selectedTag.isNotEmpty
                                    ? selectedTag
                                    : resetNotesFilterValue,
                            items: tagOptions(),
                            onChanged: (value) {
                              if (value == resetNotesFilterValue) {
                                setState(() {
                                  selectedTag = "";
                                });
                                return;
                              }
                              setState(() {
                                selectedTag = value ?? resetNotesFilterValue;
                              });
                            },
                          ),
                        )
                        : Container(),
                    for (var note in filteredNotes())
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
                        onTagsChanged: (updatedTags) {
                          var removed = note.tags.where((tag) {
                            return !updatedTags.contains(tag);
                          });
                          var added = updatedTags.where((tag) {
                            return !note.tags.contains(tag) &&
                                !tags.contains(tag);
                          });
                          setState(() {
                            for (var tag in removed) {
                              tags.remove(tag);
                            }
                            tags.addAll(added);

                            note.tags.clear();
                            note.tags.addAll(tags);
                          });
                        },
                      ),
                  ],
                ),
              ),
    );
  }
}
