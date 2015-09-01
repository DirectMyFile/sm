library sm.io;

import "dart:io";
import "dart:math";

import "vm.dart";

class SMIO {
  final SM vm;

  Random random = new Random();
  Map<int, RawSocket> sockets = {};

  SMIO(this.vm);

  bool _lineMode;
  bool _echoMode;

  setup() async {
    _lineMode = stdin.lineMode;
    stdin.lineMode = false;
    _echoMode = stdin.echoMode;
    stdin.echoMode = false;

    String getStackString(SMState sm) {
      var len = sm.pop();
      var list = [];
      for (var i = 0; i < len; i++) {
        list.add(sm.pop());
      }
      return new String.fromCharCodes(list.reversed);
    }

    var sockid = 0;

    vm.syscalls[50] = (SMState sm) async {
      var host = getStackString(sm);
      var port = sm.pop();
      var id = sockid++;
      sockets[id] = await RawSocket.connect(host, port);
      return id;
    };
    vm.syscalls[42] = (SMState sm) => sm.push(stdin.readByteSync());
    vm.syscalls[41] = (SMState sm) => stdout.add([sm.pop()]);
    vm.syscalls[20] = (SMState sm) => sleep(new Duration(milliseconds: sm.pop()));
    vm.syscalls[30] = (SMState sm) => sm.push(random.nextInt(100));
    vm.syscalls[31] = (SMState sm) => sm.push(random.nextInt(sm.pop()));
    vm.syscalls[39] = (SMState sm) {
      var count = sm.pop();
      var val = sm.pop();
      for (var i = 1; i <= count; i++) {
        sm.push(val);
      }
    };

    vm.syscalls[91] = (SMState sm) {
      var str = getStackString(sm);
      stdout.write(str);
    };

    vm.syscalls[92] = (SMState sm) {
      var str = getStackString(sm);
      print(str);
    };
  }

  teardown() async {
    sockets.values.forEach((x) {
      try {
        x.shutdown(SocketDirection.BOTH);
        x.close();
      } catch (e) {}
    });

    stdin.lineMode = _lineMode;
    stdin.echoMode = _echoMode;
  }
}