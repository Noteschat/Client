import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:noteschat/components/AddContact/AddContact.dart';
import 'package:noteschat/components/AddContact/UserCard.dart';
import 'package:noteschat/dtos/Chat.dart';
import 'package:noteschat/login.dart';

class NewChatView extends StatefulWidget {
  final String host;

  const NewChatView({super.key, required this.host});

  @override
  // ignore: no_logic_in_create_state
  State<NewChatView> createState() => _NewChatViewState(host);
}

class _NewChatViewState extends State<NewChatView> {
  final formKey = GlobalKey<FormState>();
  final nameController = TextEditingController();
  final filterController = TextEditingController();

  List<User> selectedContacts = [];
  bool hasContacts = true;
  List<User> contacts = [];
  String searchTerm = "";

  _NewChatViewState(String host) {
    fetch(host);
    filterController.addListener(searchContacts);
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
            if (tasks.length <= 0) {
              setState(() {
                hasContacts = true;
              });
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

  List<User> unselectedContacts() {
    return contacts.where((contact) {
      return !selectedContacts.contains(contact) &&
          (searchTerm.isEmpty || contact.name.contains(searchTerm));
    }).toList();
  }

  List<User> filteredSelectedContacts() {
    return selectedContacts.where((contact) {
      return searchTerm.isEmpty || contact.name.contains(searchTerm);
    }).toList();
  }

  void searchContacts() {
    setState(() {
      searchTerm = filterController.text;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surfaceBright,
        title: const Text("Start a new Chat"),
        actions: [
          Padding(
            padding: EdgeInsets.only(right: 8.0),
            child: IconButton(
              onPressed: () async {
                User? newContact = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AddContactView(host: widget.host),
                  ),
                );

                if (newContact != null && !contacts.contains(newContact)) {
                  setState(() {
                    contacts.add(newContact);
                    selectedContacts.add(newContact);
                  });
                }
              },
              icon: Icon(Icons.person_add),
            ),
          ),
        ],
      ),
      body:
          contacts.isNotEmpty
              ? Form(
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
                            decoration: const InputDecoration(
                              labelText: "Name",
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return "Enter a name...";
                              }
                              return null;
                            },
                          ),
                          TextField(
                            controller: filterController,
                            decoration: const InputDecoration(
                              labelText: "Filter Contacts",
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: FractionallySizedBox(
                              widthFactor: 1,
                              child: Column(
                                children: [
                                  Column(
                                    children:
                                        filteredSelectedContacts().isEmpty
                                            ? []
                                            : [
                                              header("Selected"),
                                              for (var contact
                                                  in filteredSelectedContacts())
                                                UserCard(
                                                  user: contact,
                                                  selectUser: () {
                                                    setState(() {
                                                      selectedContacts.remove(
                                                        contact,
                                                      );
                                                    });
                                                  },
                                                  showDivider: false,
                                                ),
                                            ],
                                  ),
                                  header("Unselected"),
                                  for (var contact in unselectedContacts())
                                    UserCard(
                                      user: contact,
                                      selectUser: () {
                                        setState(() {
                                          selectedContacts.add(contact);
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
                        onPressed:
                            selectedContacts.isEmpty
                                ? null
                                : () async {
                                  if (formKey.currentState!.validate()) {
                                    try {
                                      var res = await http.post(
                                        Uri.parse(
                                          "http://${widget.host}/api/chat/storage",
                                        ),
                                        headers: headers,
                                        body: jsonEncode({
                                          "users": [
                                            user.id,
                                            for (var contact
                                                in selectedContacts)
                                              contact.id,
                                          ],
                                          "name": nameController.text,
                                        }),
                                      );
                                      if (res.statusCode != 200) {
                                        showDialog(
                                          context: context,
                                          builder: (context) {
                                            return AlertDialog(
                                              title: Text(
                                                "Creating Chat Failed",
                                              ),
                                              content: Text(
                                                "It seems like we couldn't create the chat. Please try again later.",
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
                                      var newId = jsonDecode(res.body)["id"];
                                      Navigator.of(context).pop(
                                        Chat(
                                          id: newId,
                                          name: nameController.text,
                                        ),
                                      );
                                    } catch (e) {
                                      showDialog(
                                        context: context,
                                        builder: (context) {
                                          return AlertDialog(
                                            title: Text("Creating Chat Failed"),
                                            content: Text(
                                              "It seems like we couldn't create the chat. Please contact your administrator.",
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
                                  }
                                },
                        child: const Text("Start Chat"),
                      ),
                    ),
                  ],
                ),
              )
              : Center(
                child: Text(
                  hasContacts
                      ? "Loading Contacts..."
                      : "You have no contacts to start a chat with.",
                ),
              ),
    );
  }
}
