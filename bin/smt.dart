import "dart:io";
import "dart:math";

import "package:sm/vm.dart";
import "package:sm/smt.dart";

Random random = new Random();

main(List<String> args) async {
  if (args.length != 1) {
    print("Usage: smt <program>");
    exit(1);
  }

  var file = new File(args[0]);
  List<int> prog = parseTextualProgram(file.readAsStringSync());

  var vm = new SM();

  stdin.lineMode = false;
  stdin.echoMode = false;

  String getStackString(SMState sm) {
    var len = sm.pop();
    var list = [];
    for (var i = 0; i < len; i++) {
      list.add(sm.pop());
    }
    return new String.fromCharCodes(list.reversed);
  }

  Map<int, RawSocket> sockets = {};

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

  try {
    await vm.exec(prog);
  } catch (e, stack) {
    if (e is! SMError) {
      rethrow;
    }
    print("\n\x1b[31mVM Error\x1b[0m: ${e.msg}");
    if (const bool.fromEnvironment("verbose", defaultValue: false)) {
      print(stack);
    }
  }

  if (const bool.fromEnvironment("save.state")) {
    print(vm.saveState());
  }
}
