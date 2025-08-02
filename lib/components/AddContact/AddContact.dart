import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:noteschat/components/AddContact/UserCard.dart';
import 'package:noteschat/dtos/Chat.dart';
import 'package:noteschat/login.dart';

class AddContactView extends StatefulWidget {
  final String host;

  const AddContactView({super.key, required this.host});

  @override
  // ignore: no_logic_in_create_state
  State<AddContactView> createState() => _AddContactViewState(host);
}

class _AddContactViewState extends State<AddContactView> {
  final formKey = GlobalKey<FormState>();
  final nameController = TextEditingController();
  Timer? debounce;

  List<User> contacts = [];
  List<User> users = [];

  _AddContactViewState(String host) {
    fetch(host);
    nameController.addListener(onSearchTermChanged);
  }

  void onSearchTermChanged() {
    if (debounce?.isActive ?? false) debounce!.cancel();

    debounce = Timer(const Duration(milliseconds: 400), () async {
      final searchTerm = nameController.text;
      if (searchTerm.isNotEmpty) {
        await http
            .post(
              Uri.parse("http://${widget.host}/api/identity/search"),
              body: jsonEncode({"name": searchTerm}),
            )
            .then((res) {
              setState(() {
                users.clear();
              });
              if (res.statusCode == 200) {
                var searchRes = jsonDecode(res.body)["users"];
                for (var userJson in searchRes) {
                  setState(() {
                    var user = User.fromJson(userJson);
                    users.add(user);
                  });
                }
              } else {
                showDialog(
                  context: context,
                  builder: (context) {
                    return AlertDialog(
                      title: Text("Searching Users Failed"),
                      content: Text(
                        "It seems like we couldn't search for users. Please try again later.",
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
            });
      } else {
        setState(() {
          users.clear();
        });
      }
    });
  }

  void fetch(String host) async {
    await http
        .get(Uri.parse("http://$host/api/contacts/list"), headers: headers)
        .then((res) async {
          if (res.statusCode == 200) {
            var contactsRes = jsonDecode(res.body)["contacts"];
            List<Future> tasks = [];
            for (var contact in contactsRes) {
              tasks.add(fetchUser(host, contact["id"]));
            }

            await Future.wait(tasks);
          } else {
            showDialog(
              context: context,
              builder: (context) {
                return AlertDialog(
                  title: Text("Getting Contacts Failed"),
                  content: Text(
                    "It seems like we couldn't get your contacts. Please try again later.",
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
        });
  }

  Future fetchUser(String host, String userId) async {
    return http
        .get(
          Uri.parse("http://$host/api/identity/user/$userId"),
          headers: headers,
        )
        .then((res) {
          if (res.statusCode == 200) {
            var userRes = jsonDecode(res.body);
            setState(() {
              var contact = User.fromJson(userRes);
              contacts.add(contact);
            });
          } else {
            print("Failed to get user");
            print(res.statusCode);
          }
        });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surfaceBright,
        title: const Text("Search for a new Contact"),
      ),
      body: Padding(
        padding: EdgeInsets.all(24.0),
        child: Column(
          children: [
            Form(
              key: formKey,
              child: TextFormField(
                controller: nameController,
                decoration: const InputDecoration(labelText: "Search by Name"),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return "Enter a name...";
                  }
                  return null;
                },
              ),
            ),
            Padding(padding: EdgeInsets.only(bottom: 8.0)),
            for (user in users)
              UserCard(
                user: user,
                selectUser: () async {
                  await http.post(
                    Uri.parse(
                      "http://${widget.host}/api/contacts/list/${user.id}",
                    ),
                    headers: headers,
                  );
                  Navigator.of(context).pop(user);
                },
              ),
          ],
        ),
      ),
    );
  }
}
