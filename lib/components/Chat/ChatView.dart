import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:noteschat/components/Chat/ChatMessage.dart';
import 'package:noteschat/components/Chat/MessageQueue.dart';
import 'package:noteschat/components/NotesSelect/NotesSelect.dart';
import 'package:noteschat/dtos/ServerMessage.dart';
import 'package:noteschat/dtos/StorageMessage.dart';
import 'package:noteschat/login.dart';
import 'package:uuid/v4.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
// ignore: depend_on_referenced_packages
import 'package:web_socket/web_socket.dart';
import 'package:http/http.dart' as http;

class ChatView extends StatefulWidget {
  final String chatId, host;
  const ChatView({super.key, required this.chatId, required this.host});

  @override
  State<ChatView> createState() => _ChatViewState(host);
}

class _ChatViewState extends State<ChatView> with WidgetsBindingObserver {
  WebSocketChannel? _connector;
  bool connected = false;
  bool disposing = false;
  List<ServerMessage> messages = [];
  bool callBackAdded = false;
  bool deletingMessage = false;
  bool addingNote = false;
  late Queue queue;

  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  _ChatViewState(String host) {
    queue = Queue(
      handleMessage: (data) {
        if (messages.last.messageId == data.messageId) {
          if (data.version > messages.last.version) {
            setState(() {
              messages.last = ServerMessage(
                content: messages.last.content + data.content,
                userId: data.userId,
                messageId: data.messageId,
                version: data.version,
                chatId: data.chatId,
              );
            });
          }
        } else {
          setState(() {
            messages.add(data);
          });
        }
      },
    );
    setup(host);
  }

  void setup(String host) async {
    if (disposing) {
      return;
    }
    try {
      if (_connector != null) {
        _connector?.sink.close();
        _connector = null;
      }
      _connector = WebSocketChannel.connect(
        Uri.parse('ws://$host/api/chatrouter?sessionId=$sessionId'),
      );
      await _connector?.ready;
      WidgetsBinding.instance.scheduleFrameCallback((_) {
        if (disposing) {
          return;
        }
        setState(() {
          connected = true;
        });
        addListener(host);
      });
      return;
    } on SocketException catch (e) {
      print("$e");
    } on WebSocketChannelException catch (e) {
      // ignore: unrelated_type_equality_checks
      if (e.inner.runtimeType == "WebSocketException") {
        print((e.inner as WebSocketException).message);
      } else {
        print("$e");
      }
    } catch (e) {
      print("Unexpected Exception: $e");
    }
    print("Trying again in 1 second.");
    await Future.delayed(Duration(seconds: 1));
    setup(host);
  }

  void addListener(String host) {
    if (_connector != null && connected) {
      try {
        _connector?.stream.listen(
          (data) {
            ServerMessage serverJson = ServerMessage.fromJson(
              jsonDecode(data as String),
            );
            if (serverJson.chatId == widget.chatId) {
              setState(() {
                queue.add(serverJson);
              });
            }
          },
          onDone: () {
            if (disposing) {
              return;
            }
            // server closed, reconnecting
            setState(() {
              connected = false;
            });
            setup(host);
          },
          onError: (_) {
            if (disposing) {
              return;
            }
            // connection lost, reconnecting
            setState(() {
              connected = false;
            });
            setup(host);
          },
        );
      } catch (_) {
        setup(host);
      }
      fetch();
    }
  }

  void fetch() async {
    if (disposing) {
      return;
    }
    try {
      // to prevent skipping messages, we wait for the next block for up to 5-seconds
      int waited = 0;
      while (queue.length() <= 0 && waited < 50) {
        await Future.delayed(Duration(milliseconds: 100));
        waited++;
      }

      var res = await http.get(
        Uri.parse("http://${widget.host}/api/chat/storage/${widget.chatId}"),
        headers: headers,
      );

      if (res.statusCode == 200) {
        List<dynamic> msgs = jsonDecode(res.body)["messages"];
        for (var message in msgs) {
          StorageMessage msg = StorageMessage.fromJson(message);
          setState(() {
            messages.add(
              ServerMessage(
                version: msg.version,
                messageId: msg.messageId,
                content: msg.content,
                chatId: widget.chatId,
                userId: msg.userId,
              ),
            );
          });
        }
        setState(() {
          queue.fetching = false;
        });
      } else {
        showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: Text("Getting Chat Failed"),
              content: Text(
                "It seems like we couldn't get your chat. Please try again later.",
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
    } catch (e) {}
  }

  void onPressed(ServerMessage message) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Message"),
          content: Text("What do you want to do?"),
          actions: [
            OutlinedButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text("Cancel"),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(context);

                onAddNote(message);
              },
              child: Icon(Icons.note_add_outlined),
            ),
            FilledButton(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: message.content));
                Navigator.pop(context);
              },
              child: Icon(Icons.copy),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(context);

                onDelete(message);
              },
              child: Icon(Icons.delete_outline),
            ),
          ],
        );
      },
    );
  }

  void onAddNote(ServerMessage message) {
    final TextEditingController _noteNameController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Save as Note"),
          content: TextField(
            controller: _noteNameController,
            decoration: InputDecoration(hintText: "Note name"),
          ),
          actions: [
            OutlinedButton(
              onPressed: () {
                Navigator.pop(context);
                onPressed(message);
              },
              child: Text("Cancel"),
            ),
            FilledButton(
              onPressed: () async {
                setState(() {
                  addingNote = true;
                });
                try {
                  var res = await http.post(
                    Uri.parse(
                      "http://${widget.host}/api/notes/storage/${widget.chatId}",
                    ),
                    headers: headers,
                    body: jsonEncode({
                      "name": _noteNameController.text,
                      "content": message.content,
                    }),
                  );
                  if (res.statusCode != 200) {
                    onError("Couldn't save message as note!");
                    return;
                  }
                } catch (e) {
                  onError("Couldn't save message as note!\n${e.toString()}");
                  return;
                }

                setState(() {
                  addingNote = false;
                });

                Navigator.pop(context);
              },
              child: addingNote ? Icon(Icons.circle_outlined) : Text("Save"),
            ),
          ],
        );
      },
    );
  }

  void onDelete(ServerMessage message) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Delete Message"),
          content: Text("Do you really want to delete this message?"),
          actions: [
            OutlinedButton(
              onPressed: () {
                Navigator.pop(context);
                onPressed(message);
              },
              child: Text("Cancel"),
            ),
            FilledButton(
              onPressed: () async {
                setState(() {
                  deletingMessage = true;
                });
                try {
                  var res = await http.delete(
                    Uri.parse(
                      "http://${widget.host}/api/chat/storage/${widget.chatId}/${message.messageId}",
                    ),
                    headers: headers,
                  );
                  if (res.statusCode != 200) {
                    onError("Couldn't delete message!");
                    return;
                  }
                } catch (e) {
                  onError("Couldn't delete message!\n${e.toString()}");
                  return;
                }

                setState(() {
                  messages.remove(message);

                  deletingMessage = false;
                });

                Navigator.pop(context);
              },
              child:
                  deletingMessage
                      ? Icon(Icons.circle_outlined)
                      : Text("Delete"),
            ),
          ],
        );
      },
    );
  }

  void onError(String message) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Delete Message Error"),
          content: Text(message),
          actions: [
            OutlinedButton(
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surfaceBright,
        title: Text("Chat"),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: Icon(connected ? Icons.wifi : Icons.wifi_off),
          ),
          Padding(
            padding: EdgeInsets.only(right: 8.0),
            child: IconButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder:
                        (context) => NotesSelect(
                          chatId: widget.chatId,
                          host: widget.host,
                        ),
                  ),
                );
              },
              icon: Icon(Icons.library_books_outlined),
            ),
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
                    for (var message in messages)
                      Message(data: message, onPressed: onPressed),
                  ],
                ),
              ),
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
                    onPressed:
                        connected && !queue.fetching
                            ? () {
                              var value = _controller.text;
                              var message = ServerMessage(
                                content: value,
                                userId: user.id,
                                messageId: UuidV4().generate(),
                                version: 0,
                                chatId: widget.chatId,
                              );
                              setState(() {
                                messages.add(message);
                              });
                              _connector?.sink.add(
                                jsonEncode(message.toJson()),
                              );
                              _controller.clear();
                              _focusNode.requestFocus();
                            }
                            : null,
                    icon: Icon(Icons.send),
                  ),
                ),
              ],
            ),
          ),
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
