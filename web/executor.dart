import "dart:html";

import "package:sm/smt.dart";
import "package:sm/vm.dart";

const String DEFAULT_CODE = """\
PSH 5 # Starting Point
DUP # Duplicate
PRNT # Print Value
PSH 1 # Push 1
SUB # Subtract 1 from the Value
DUP # Duplicate
PSH 0 # Push 0
PSH 11 # Push 11
JIE # Jump to End
PSH 1 # Instruction 1
JMP # Jump to Instruction 1
HLT # Halt
""";

main() async {
  window.onMessage.listen((MessageEvent event) async {
    var data = event.data;

    if (data["program"] != null) {
      await execute(data["program"]);
    }
  });

  window.postMessage({
    "code": DEFAULT_CODE
  }, "*");

  window.postMessage({
    "instructions": INST_NAMES.values.toList()
  }, "*");
}

execute(String input) async {
  var program = parseTextualProgram(input);
  var vm = new SM();
  vm.printFunction = (input) {
    window.postMessage({
      "print": input.toString()
    }, "*");
  };

  String getStackString(SMState sm) {
    var len = sm.pop();
    var list = [];
    for (var i = 0; i < len; i++) {
      list.add(sm.pop());
    }
    return new String.fromCharCodes(list.reversed);
  }

  vm.syscalls[1] = (SMState state) {
    window.alert(getStackString(state));
  };
  await vm.exec(program);
}
