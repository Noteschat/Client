
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:noteschat/dtos/Chat.dart';
import 'package:noteschat/login.dart';

class NewChatView extends StatefulWidget {
  final List<User> users;
  final String host;

  const NewChatView({super.key, required this.users, required this.host});

  @override
  // ignore: no_logic_in_create_state
  State<NewChatView> createState() => _NewChatViewState(users: users);
}

class _NewChatViewState extends State<NewChatView> {
  final formKey = GlobalKey<FormState>();
  final nameController = TextEditingController();
  final List<User> users;

  late User selectedUser;

  _NewChatViewState({required this.users}) {
    selectedUser = users.first;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surfaceBright,
        title: const Text("Start a new Chat"),
      ),
      body: Form(
        key: formKey,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  TextFormField(
                    controller: nameController,
                    decoration: const InputDecoration(labelText: "Name"),
                    validator: (value) {
                      if(value == null || value.isEmpty){
                        return "Enter a name...";
                      }
                      return null;
                    },
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: FractionallySizedBox(
                      widthFactor: 1,
                      child: DropdownButton<User>(
                        value: selectedUser,
                        items: users.map<DropdownMenuItem<User>>((User user) {
                          return DropdownMenuItem<User>(value: user, child: Text(user.name));
                        }).toList(),
                        onChanged: (user) {
                          setState(() {
                            selectedUser = user!;
                          });
                        }
                      ),
                    ),
                  )
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: FilledButton(
                onPressed: () async {
                  if (formKey.currentState!.validate()) {
                    try {
                      var res = await http.post(
                        Uri.parse("http://${widget.host}/api/chat/storage"),
                        headers: headers,
                        body: jsonEncode({
                          "users": [
                            user.id,
                            selectedUser.id
                          ],
                          "name": nameController.text,
                        })
                      );
                      if(res.statusCode != 200) {
                        showDialog(
                          context: context,
                          builder: (context) {
                            return AlertDialog(
                              title: Text("Creating Chat Failed"),
                              content: Text("It seems like we couldn't create the chat. Please try again later."),
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
                        Chat(id: newId, name: nameController.text)
                      );
                    } catch (e) {
                      showDialog(
                        context: context,
                        builder: (context) {
                          return AlertDialog(
                            title: Text("Creating Chat Failed"),
                            content: Text("It seems like we couldn't create the chat. Please contact your administrator."),
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
                },
                child: const Text("Start Chat"),
              ),
            )
          ]
        )
      )
    );
  }
}
