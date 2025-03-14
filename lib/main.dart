import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/services.dart';
import 'package:uuid/v4.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket/web_socket.dart';
import 'package:http/http.dart' as http;

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: []);

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
          home: MyHomePage(title: "Chat Notes"),
        );
      },
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> with WidgetsBindingObserver {
  WebSocketChannel? _connector;
  bool connected = false;
  List<MessageData> messages = [];
  bool callBackAdded = false;
  String lastId = "";

  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  _MyHomePageState() {
    setup();
  }

  void setup() async {
    try {
      if(_connector != null){
        _connector?.sink.close();
        _connector = null;
      }
      _connector = WebSocketChannel.connect(Uri.parse('ws://localhost:6798'));
      await _connector?.ready;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        setState(() {
          connected = true;
        });
        addListener();
      });
      return;
    } on SocketException catch(e) {
      print("${e}");
    } on WebSocketChannelException catch (e) {
      if(e.inner.runtimeType == "WebSocketException") {
        print((e.inner as WebSocketException).message);
      } else {
        print("${e}");
      }
    } catch(e) {
      print("Unexpected Exception: ${e}");
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
            var dataParts = (data as String).split("\n");
            var msgId = dataParts[0];
            var text = dataParts.sublist(1).join('\n');
            setState(() {
              if(msgId == lastId){
                messages.last = MessageData(
                  text: messages.last.text + text,
                  sentBySelf: false
                );
              } else{
                messages.add(MessageData(
                  text: text,
                  sentBySelf: false
                ));
                lastId = msgId;
              }
            });
          },
          onDone: () {
            print("Server closed Connection. Trying to reconnect");
              setState(() {
                connected = false;
              });
            setup();
          },
          onError: (_) {
            print("Connection to server lost. Trying to reconnect");
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
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surfaceBright,
        title: Text(widget.title),
        actions: [
          Padding(
            padding: EdgeInsets.only(right: 24.0),
            child: Icon(connected ? Icons.wifi : Icons.wifi_off)
          ),
        ],
      ),
      drawer: NavigationDrawer(
        children: [
          
        ]
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
                      labelText: 'Type something and press Enter',
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 12.0, bottom: 20.0),
                  child: IconButton.filled(
                    onPressed: () {
                      var value = _controller.text;
                      setState(() {
                        messages.add(MessageData(
                          text: value, 
                          sentBySelf: true
                        ));
                      });
                      var msg = "${UuidV4().generate()}\n$value";
                      _connector?.sink.add(msg);
                      _controller.clear();
                      _focusNode.requestFocus();
                    }, 
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
}

class MessageData {
  final String text;
  final bool sentBySelf;

  MessageData({required this.text, required this.sentBySelf});
}

class Message extends StatelessWidget {
  final MessageData data;

  const Message({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: 8.0),
      child: Row(
        mainAxisAlignment: data.sentBySelf ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          Flexible( // Allows the container to be constrained within available space
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.8, // Maximum width is 80% of screen width
              ),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.only(
                    topLeft: data.sentBySelf ? Radius.circular(20) : Radius.circular(0), 
                    topRight: data.sentBySelf ? Radius.circular(0) : Radius.circular(20), 
                    bottomLeft: Radius.circular(20), 
                    bottomRight: Radius.circular(20)
                  ),
                  color: data.sentBySelf
                      ? Theme.of(context).colorScheme.secondaryContainer
                      : Theme.of(context).colorScheme.tertiaryContainer,
                ),
                padding: const EdgeInsets.all(16.0), // Adds padding around the text
                child: Text(
                  data.text,
                  textAlign: data.sentBySelf ? TextAlign.right : TextAlign.left,
                ),
              ),
            ),
          ),
        ],
      )
    );
  }
  
}