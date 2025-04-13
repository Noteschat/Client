// ignore_for_file: avoid_print

import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'package:uuid/v4.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
// ignore: depend_on_referenced_packages
import 'package:web_socket/web_socket.dart';
import 'package:http/http.dart' as http;

String host = "localhost";
late User user;
String sessionId = "";

var headers = <String, String>{
  "Cookie": "sessionId=$sessionId"
};

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return DynamicColorBuilder(
      builder: (ColorScheme? lightDynamic, ColorScheme? darkDynamic) {
        ColorScheme lightColorScheme;
        ColorScheme darkColorScheme;

        if (lightDynamic != null && darkDynamic != null) {
          lightColorScheme = lightDynamic;
          darkColorScheme = darkDynamic;
        } else {
          lightColorScheme = ColorScheme.fromSeed(seedColor: Colors.blue);
          darkColorScheme = ColorScheme.fromSeed(
            seedColor: Colors.blue,
            brightness: Brightness.dark,
          );
        }

        return MaterialApp(
          title: 'Chat Notes',
          theme: ThemeData(colorScheme: lightColorScheme, useMaterial3: true),
          darkTheme: ThemeData(
            colorScheme: darkColorScheme,
            useMaterial3: true,
          ),
          home: ChatSelect(),
        );
      },
    );
  }
}

class ChatSelect extends StatefulWidget {
  const ChatSelect({super.key});

  @override
  State<ChatSelect> createState() => _ChatSelectState();
}

class _ChatSelectState extends State<ChatSelect> {
  List<Chat> chats = [];

  _ChatSelectState() {
    setup();
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
              icon: Icon(Icons.add),
              onPressed: () async {
                Chat? newChat = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => NewChatView()
                  )
                );
                if(newChat != null) {
                  setState(() {
                    chats.add(newChat);
                  });

                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => ChatView(chatId: newChat.id)
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
              )
            ],
          ),
        ),
      ),
    );
  }

  void setup() async {
    try {
      while(sessionId.isEmpty){
        var res = await http.post(Uri.parse('http://$host/api/identity/login'), headers: {
          "Content-Type": "application/json; charset=UTF-8"
        }, body: jsonEncode({
          "name": "Admin",
          "password": "adminPassword"
        }));
        var cookie = res.headers['set-cookie'];
        sessionId = cookie?.split('sessionId=')[1].split(';')[0] ?? "";
        await Future.delayed(Duration(seconds: 1));
      }

      var userRes = await http.get(Uri.parse("http://$host/api/identity/login/valid"), headers: headers);
      if(userRes.statusCode != 200){
        print(userRes.statusCode);
        return;
      }
      user = User.fromJson(jsonDecode(userRes.body));
    }
    catch (e) {
      print("Unexpected Exception: $e");
    }

    fetch();
  }

  void fetch() async {
    var storageRes = await http.get(Uri.parse("http://$host/api/chat/storage"), headers: headers);
    if(storageRes.statusCode == 200) {
      var chatsRes = jsonDecode(storageRes.body)["chats"];
      setState(() {
        for(var chat in chatsRes){
          chats.add(Chat.fromJson(chat));
        }
      });
    } else {
      print(storageRes.statusCode);
    }
  }
}

class ChatCard extends StatelessWidget {
  final Chat chat;
  final Function removeChat;

  const ChatCard({super.key, required this.chat, required this.removeChat});
  
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        FractionallySizedBox(
          widthFactor: 1,
          child: GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ChatView(chatId: chat.id,)
                )
              );
            },
            onLongPress: () {
              showDialog(
                context: context,
                builder: (context) {
                  return AlertDialog(
                    title: Text("Delete Chat"),
                    content: Text("Do you really wish to delete this chat?"),
                    actions: [
                      OutlinedButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        child: Text(
                          "Cancel", 
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurfaceVariant
                          ),
                        )
                      ),
                      FilledButton(
                        style: ButtonStyle(
                          backgroundColor: WidgetStateColor.resolveWith((states) {
                            if (states.contains(WidgetState.pressed)) {
                              return Theme.of(context).colorScheme.error.withValues(alpha: 0.7); // Error color when pressed
                            }
                            return Theme.of(context).colorScheme.error; // Default error color
                          }),
                        ),
                        onPressed: () async {
                          await http.delete(Uri.parse("http://$host/api/chat/storage/${chat.id}"), headers: headers);
                          removeChat();
                          Navigator.of(context).pop();
                        }, 
                        child: Text(
                          "Delete",
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onError
                          ),
                        )
                      )
                    ],
                  );
                }
              );
            },
            child: Padding(
              padding: const EdgeInsets.only(top: 8.0, bottom: 8.0),
              child: Text(chat.name, textAlign: TextAlign.center,),
            ),
          ),
        ),
        Divider()
      ],
    );
  }
  
}

class NewChatView extends StatelessWidget {
  final formKey = GlobalKey<FormState>();
  final nameController = TextEditingController();

  NewChatView({super.key});
  
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
            Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: FilledButton(
                onPressed: () async {
                  if (formKey.currentState!.validate()) {
                    try {
                      var res = await http.post(
                        Uri.parse("http://$host/api/chat/storage"),
                        headers: headers,
                        body: jsonEncode({
                          "users": [
                            user.id,
                            "7370a454-153c-4964-b411-b44194ee3acb"
                          ],
                          "name": nameController.text,
                        })
                      );
                      if(res.statusCode != 200) {
                        print(res.statusCode);
                        return;
                      }
                      var newId = jsonDecode(res.body)["id"];
                      Navigator.of(context).pop(
                        Chat(id: newId, name: nameController.text)
                      );
                    } catch (e) {
                      print("Error on Chat creation:");
                      print(e);
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

class ChatView extends StatefulWidget {
  final String chatId;
  const ChatView({super.key, required this.chatId});

  @override
  State<ChatView> createState() => _ChatViewState();
}

class _ChatViewState extends State<ChatView> with WidgetsBindingObserver {
  WebSocketChannel? _connector;
  bool connected = false;
  bool disposing = false;
  List<ServerMessage> messages = [];
  bool callBackAdded = false;
  late Queue queue;

  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  _ChatViewState() {
    queue = Queue(handleMessage: (data) {
      if(messages.last.messageId == data.messageId) {
        if(data.version > messages.last.version) {
          setState(() {
            messages.last = ServerMessage(
              content: messages.last.content + data.content,
              userId: data.userId,
              messageId: data.messageId,
              version: data.version,
              chatId: data.chatId
            );
          });
        }
      } else {
        setState(() {
          messages.add(data);
        });
      }
    });
    setup();
  }

  void setup() async {
    if(disposing){
      return;
    }
    try {
      if(_connector != null){
        _connector?.sink.close();
        _connector = null;
      }
      _connector = WebSocketChannel.connect(Uri.parse('ws://$host/api/chatrouter?sessionId=$sessionId'));
      await _connector?.ready;
      WidgetsBinding.instance.scheduleFrameCallback((_) {
        if(disposing) {
          return;
        }
        setState(() {
          connected = true;
        });
        addListener();
      });
      return;
    } on SocketException catch(e) {
      print("$e");
    } on WebSocketChannelException catch (e) {
      // ignore: unrelated_type_equality_checks
      if(e.inner.runtimeType == "WebSocketException") {
        print((e.inner as WebSocketException).message);
      } else {
        print("$e");
      }
    } catch(e) {
      print("Unexpected Exception: $e");
    }
    print("Trying again in 1 second.");
    await Future.delayed(Duration(seconds: 1));
    setup();
  }

  void addListener() {
    if(_connector != null && connected){
      try {
        _connector?.stream.listen(
          (data) {
            ServerMessage serverJson = ServerMessage.fromJson(jsonDecode(data as String));            
            setState(() {
              queue.add(serverJson);
            });
          },
          onDone: () {
            if(disposing) {
              return;
            }
            // server closed, reconnecting
            setState(() {
              connected = false;
            });
            setup();
          },
          onError: (_) {
            if(disposing) {
              return;
            }
            // connection lost, reconnecting
            setState(() {
              connected = false;
            });
            setup();
          }
        );
      }
      catch (_) {
        setup();
      }
      fetch();
    }
  }

  void fetch() async {
    if(disposing) {
      return;
    }
    try {
      // to prevent skipping messages, we wait for the next block for up to 5-seconds
      int waited = 0;
      while(queue.length() <= 0 && waited < 50){
        await Future.delayed(Duration(milliseconds: 100));
        waited++;
      }

      var res = await http.get(Uri.parse("http://$host/api/chat/storage/${widget.chatId}"), headers: headers);

      if(res.statusCode == 200) {
        List<dynamic> msgs = jsonDecode(res.body)["messages"];
        for(var message in msgs) {
          StorageMessage msg = StorageMessage.fromJson(message);
          setState(() {
            messages.add(ServerMessage(
              version: msg.version,
              messageId: msg.messageId,
              content: msg.content,
              chatId: widget.chatId,
              userId: msg.userId
            ));
          });
        }
        setState(() {
          queue.fetching = false;
        });
      }else{
        print("Couldn't get Chat: ${res.statusCode}");
      }
    } catch (e) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surfaceBright,
        title: Text("Chat"),
        actions: [
          Padding(
            padding: EdgeInsets.only(right: 24.0),
            child: Icon(connected ? Icons.wifi : Icons.wifi_off)
          ),
        ],
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(left: 8.0, right: 8.0),
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    for(var message in messages) Message(data: message)
                  ]
                ),
              )
            ),
          ),
          Padding(
            padding: EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    focusNode: _focusNode,
                    minLines: 1,
                    maxLines: 4,
                    maxLength: 65000,
                    textInputAction: TextInputAction.newline,
                    keyboardType: TextInputType.multiline,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: 'Type something...',
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 12.0, bottom: 20.0),
                  child: IconButton.filled(
                    onPressed: connected && !queue.fetching ? () {
                      var value = _controller.text;
                      var message = ServerMessage(
                        content: value, 
                        userId: user.id,
                        messageId: UuidV4().generate(),
                        version: 0,
                        chatId: widget.chatId
                      );
                      setState(() {
                        messages.add(message);
                      });
                      _connector?.sink.add(jsonEncode(message.toJson()));
                      _controller.clear();
                      _focusNode.requestFocus();
                    } : null,
                    icon: Icon(Icons.send),
                  ),
                )
              ],
            )
          )
        ],
      ),
    );
  }

  @override
  void dispose() {
    disposing = true;
    queue.stop();
    _connector?.sink.close();
    super.dispose();
  }
}

class Message extends StatelessWidget {
  final ServerMessage data;

  const Message({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: 8.0),
      child: Row(
        mainAxisAlignment: data.userId == user.id ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          Flexible( // Allows the container to be constrained within available space
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.8, // Maximum width is 80% of screen width
              ),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.only(
                    topLeft: data.userId == user.id ? Radius.circular(20) : Radius.circular(0), 
                    topRight: data.userId == user.id ? Radius.circular(0) : Radius.circular(20), 
                    bottomLeft: Radius.circular(20), 
                    bottomRight: Radius.circular(20)
                  ),
                  color: data.userId == user.id
                      ? Theme.of(context).colorScheme.secondaryContainer
                      : Theme.of(context).colorScheme.tertiaryContainer,
                ),
                padding: const EdgeInsets.all(16.0), // Adds padding around the text
                child: Text(
                  data.content,
                  textAlign: TextAlign.left,
                ),
              ),
            ),
          ),
        ],
      )
    );
  }
}

class Queue {
  bool fetching = true;
  List<ServerMessage> queue = [];
  bool stopped = false;

  final Function(ServerMessage data) handleMessage;

  Queue({required this.handleMessage}) {
    handle();
  }

  int length() {
    return queue.length;
  }

  void add(ServerMessage data) {
    queue.add(data);
  }

  void handle() async {
    if(!stopped){
      if(!fetching) {
        List<ServerMessage> internal = [];
        internal.addAll(queue);
        queue.clear();

        for(var message in internal) {
          handleMessage(message);
        }
      }
      await Future.delayed(Duration(milliseconds: 100));
      handle();
    }
  }

  void stop() {
    stopped = true;
  }
}

class StorageMessage {
  final int version;
  final String messageId;
  final String content;
  final String userId;

  StorageMessage({required this.version, required this.messageId, required this.content, required this.userId});

  factory StorageMessage.fromJson(Map<String, dynamic> json) {
    return StorageMessage(
      version: json['version'],
      messageId: json['messageId'],
      content: json['content'],
      userId: json['userId'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'version': version,
      'messageId': messageId,
      'content': content,
      'userId': userId,
    };
  }
}

class ServerMessage {
  final int version;
  final String messageId;
  final String content;
  final String chatId;
  final String userId;

  ServerMessage({required this.version, required this.messageId, required this.content, required this.chatId, required this.userId});

  factory ServerMessage.fromJson(Map<String, dynamic> json) {
    return ServerMessage(
      version: json['version'],
      messageId: json['messageId'],
      content: json['content'],
      chatId: json['chatId'],
      userId: json['userId'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'version': version,
      'messageId': messageId,
      'content': content,
      'chatId': chatId,
      'userId': userId,
    };
  }
}

class User {
  final String id;
  final String name;

  User({required this.id, required this.name});

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      name: json['name'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
    };
  }
}

class Chat {
  final String id;
  final String name;

  Chat({required this.id, required this.name});

  factory Chat.fromJson(Map<String, dynamic> json) {
    return Chat(
      id: json['id'],
      name: json['name'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
    };
  }
}