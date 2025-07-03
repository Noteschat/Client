import 'package:noteschat/dtos/ServerMessage.dart';

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
