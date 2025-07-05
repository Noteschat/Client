import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:noteschat/dtos/Note.dart';
import 'package:noteschat/login.dart';

class NewNoteView extends StatefulWidget {
  final String host;
  final String chatId;

  const NewNoteView({super.key, required this.host, required this.chatId});

  @override
  State<NewNoteView> createState() => _NewNoteViewState();
}

class _NewNoteViewState extends State<NewNoteView> {
  final formKey = GlobalKey<FormState>();
  final nameController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surfaceBright,
        title: const Text("Create a new Note"),
      ),
      body: Form(
        key: formKey,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 24, right: 24),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: TextFormField(
                      controller: nameController,
                      decoration: const InputDecoration(labelText: "Name"),
                      validator: (value) {
                        if(value == null || value.isEmpty){
                          return "Enter a name...";
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: FilledButton(
                onPressed: () async {
                  if (!formKey.currentState!.validate()) {
                    return;
                  }
                  try {
                    var res = await http.post(
                      Uri.parse("http://${widget.host}/api/notes/storage/${widget.chatId}"),
                      headers: headers,
                      body: jsonEncode({
                        "name": nameController.text,
                        "content": ""
                      })
                    );
                    if(res.statusCode != 200) {
                      showDialog(
                        context: context,
                        builder: (context) {
                          return AlertDialog(
                            title: Text("Creating Note Failed"),
                            content: Text("It seems like we couldn't create the note. Please try again later."),
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
                      return;
                    }
                    var newId = jsonDecode(res.body)["id"];
                    Navigator.of(context).pop(
                      AllNote(id: newId, name: nameController.text)
                    );
                  } catch (e) {
                    showDialog(
                      context: context,
                      builder: (context) {
                        return AlertDialog(
                          title: Text("Creating Note Failed"),
                          content: Text("It seems like we couldn't create the note. Please contact your administrator."),
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
                },
                child: const Text("Create Config"),
              ),
            )
          ]
        )
      )
    );
  }
}