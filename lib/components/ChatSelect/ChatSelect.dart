import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:noteschat/components/Chat/ChatView.dart';
import 'package:noteschat/components/ChatSelect/ChatCard.dart';
import 'package:noteschat/components/NewChat/NewChat.dart';
import 'package:noteschat/dtos/Chat.dart';
import 'package:noteschat/login.dart';

class ChatSelect extends StatefulWidget {
  final String host;

  const ChatSelect({super.key, required this.host});

  @override
  State<ChatSelect> createState() => _ChatSelectState(host);
}

class _ChatSelectState extends State<ChatSelect> {
  List<Chat> chats = [];
  List<User> users = [];

  _ChatSelectState(String host) {
    fetch(host);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surfaceBright,
        title: Text("Chats"),
        actions: [
          Padding(
            padding: EdgeInsets.only(right: 24.0),
            child: IconButton(
              icon: Icon(users.isEmpty ? Icons.circle_outlined : Icons.add),
              onPressed: users.isEmpty ? null : () async {
                Chat? newChat = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => NewChatView(users: users, host: widget.host,)
                  )
                );
                if(newChat != null) {
                  setState(() {
                    chats.add(newChat);
                  });

                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => ChatView(chatId: newChat.id, host: widget.host)
                    )
                  );
                }
              },
            )
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.only(left: 8.0, right: 8.0),
          child: Column(
            children: [
              for(var chat in chats) ChatCard(
                chat: chat,
                removeChat: () {
                  setState(() {
                    chats.remove(chat);
                  });
                },
                host: widget.host,
              )
            ],
          ),
        ),
      ),
    );
  }

  void fetch(String host) async {
    List<Future> tasks = [];
    
    tasks.add(http.get(Uri.parse("http://$host/api/chat/storage"), headers: headers).then((res) {
      if(res.statusCode == 200) {
        var chatsRes = jsonDecode(res.body)["chats"];
        setState(() {
          for(var chat in chatsRes){
            chats.add(Chat.fromJson(chat));
          }
        });
      } else {
        showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: Text("Getting Chats Failed"),
              content: Text("It seems like we couldn't get your chats. Please try again later."),
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
    tasks.add(http.get(Uri.parse("http://$host/api/identity/user"), headers: headers).then((res) {
      if(res.statusCode == 200) {
        var usersRes = jsonDecode(res.body)["users"];
        setState(() {
          for(var userJson in usersRes){
            var contact = User.fromJson(userJson);
            if(contact.id != user.id) {
              users.add(contact);
            }
          }
        });
      } else {
        showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: Text("Getting Contacts Failed"),
              content: Text("It seems like we couldn't get your contacts. Please try again later."),
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
}