import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:noteschat/components/NotesSelect/TagCard.dart';
import 'package:noteschat/dtos/Note.dart';
import 'package:noteschat/login.dart';

class NotesTagsView extends StatefulWidget {
  final String host;
  final String chatId;
  final AllNote note;
  List<String> tags;

  NotesTagsView({
    super.key,
    required this.host,
    required this.chatId,
    required this.note,
    required this.tags,
  });

  @override
  State<NotesTagsView> createState() => _NotesTagsViewState(host, chatId, note);
}

class _NotesTagsViewState extends State<NotesTagsView> {
  final formKey = GlobalKey<FormState>();
  final nameController = TextEditingController();
  final filterController = TextEditingController();

  Note? note;
  bool failed = false;
  List<String> selectedTags = [];

  _NotesTagsViewState(String host, String chatId, AllNote allNote) {
    fetch(host, chatId, allNote);
  }

  void fetch(String host, String chatId, AllNote allNote) async {
    await http
        .get(
          Uri.parse("http://$host/api/notes/storage/$chatId/${allNote.id}"),
          headers: headers,
        )
        .then((val) {
          if (val.statusCode != 200) {
            setState(() {
              failed = true;
            });
            return;
          }
          var noteJson = jsonDecode(val.body);
          setState(() {
            note = Note.fromJson(noteJson);
            selectedTags = note!.tags;
          });
        })
        .catchError((e) {
          setState(() {
            failed = true;
          });
        });
  }

  List<String> unselectedTags() {
    return widget.tags.where((tag) {
      return !selectedTags.contains(tag) &&
          (filterController.text.isEmpty ||
              filterController.text.contains(tag));
    }).toList();
  }

  List<String> filteredSelectedTags() {
    return selectedTags.where((tag) {
      return filterController.text.isEmpty ||
          filterController.text.contains(tag);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surfaceBright,
        title: Text("Edit Tags of ${widget.note.name}"),
      ),
      body:
          note == null || failed
              ? Center(
                child: Text(
                  failed
                      ? "Failed to get note. Try again later."
                      : "Loading note...",
                ),
              )
              : Form(
                key: formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          TextField(
                            controller: filterController,
                            decoration: const InputDecoration(
                              labelText: "Search for Tag...",
                            ),
                            onSubmitted: (value) {
                              setState(() {
                                selectedTags.add(value);
                              });
                            },
                          ),
                          Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: FractionallySizedBox(
                              widthFactor: 1,
                              child: Column(
                                children: [
                                  Column(
                                    children:
                                        filteredSelectedTags().isEmpty
                                            ? []
                                            : [
                                              header("Selected"),
                                              for (var tag
                                                  in filteredSelectedTags())
                                                TagCard(
                                                  tag: tag,
                                                  selectTag: () {
                                                    setState(() {
                                                      selectedTags.remove(tag);
                                                      print(
                                                        selectedTags.length,
                                                      );
                                                    });
                                                  },
                                                  showDivider: false,
                                                ),
                                            ],
                                  ),
                                  header("Unselected"),
                                  for (var tag in unselectedTags())
                                    TagCard(
                                      tag: tag,
                                      selectTag: () {
                                        setState(() {
                                          selectedTags.add(tag);
                                          print(selectedTags.length);
                                        });
                                      },
                                      showDivider: false,
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 24),
                      child: FilledButton(
                        onPressed: () async {
                          try {
                            var body = jsonEncode({
                              "tags": [for (var tag in selectedTags) tag],
                              "name": note!.name,
                              "content": note!.content,
                            });
                            var res = await http.put(
                              Uri.parse(
                                "http://${widget.host}/api/notes/storage/${note!.chatId}/${note!.id}",
                              ),
                              headers: headers,
                              body: body,
                            );
                            if (res.statusCode != 200) {
                              showDialog(
                                context: context,
                                builder: (context) {
                                  return AlertDialog(
                                    title: Text("Setting Tags Failed"),
                                    content: Text(
                                      "It seems like we couldn't set the tags. Please try again later.",
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
                              return;
                            }
                            Navigator.of(context).pop(
                              Note(
                                id: note!.id,
                                name: note!.name,
                                chatId: note!.chatId,
                                content: note!.content,
                                tags: note!.tags,
                              ),
                            );
                          } catch (e) {
                            showDialog(
                              context: context,
                              builder: (context) {
                                return AlertDialog(
                                  title: Text("Setting Tags failed"),
                                  content: Text(
                                    "It seems like we couldn't set the tags. Please contact your administrator.",
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
                        },
                        child: const Text("Save Tags"),
                      ),
                    ),
                  ],
                ),
              ),
    );
  }

  Widget header(String text) {
    return Row(
      children: [
        Expanded(child: Divider()),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Text(text),
        ),
        Expanded(child: Divider()),
      ],
    );
  }
}
