import "dart:html";

import "package:sm/smt.dart";
import "package:sm/vm.dart";

const String REFERENCE = """
HLT (1): Halt Program
PSH (2): Push Value to Stack
POP (3): Pop Value from Stack
ADD (4): Add last 2 values on the stack and push the value to the stack
JMP (5): Jump Instructions
DUP (6): Duplicate Last Stack Value
JIE (7): Jump if Equal
JINE (8): Jump if Not Equal
PRNT (9): Print Last Stack Value
FLP (10): Flip
ROT (11): Rotate
OIEE (12): One if Either Equal
SUB (13): Subtract
SIZ (14): Size of Stack
PSTK (15): Print Stack
SRV (16): Set Register Value
CRS (17): Copy Register Value to Stack
ENTR (18): Create and Enter New Stack
SHFT (19): Shift Stack
RSET (20): Reset Program
LEAV (21): Leave the Current Stack
MULT (22): Multiply
NOP (23): Do Nothing
EVAL (24): Evaluate the Current Stack as a Program
CLR (25): Clear the Stack
SYSC (26): Make a System Call
CPC (27): Copy Program Code to Stack
SDUP (28): Duplicate Entire Stack
EFLP (29): Flip Every Pair of Stack Values
FRK (30): Fork a Virtual Thread
SPI (31): Set Program Instruction
CENTR (32): Copy Current Stack to a New Stack and Enter It
""";

const String COUNTDOWN_CODE = """\
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

const String FIB = """\
PSH 0
PSH 1
SRV
PSH 5 # Input
DUP
PSH 2
SRV
DUP
PSH 0
PSH 1
OIEE
PSH 1
PSH 26
JIE
SIZ
PSH 0
PSH 34
JIE
DUP
PSH 1
SUB
FLP
PSH 2
SUB
PSH 7
JMP
PSH 1
CRS
PSH 1
ADD
PSH 1
SRV
PSH 8
JMP
PSH 1
CRS
PRNT
""";

const String STACKS_CODE = """\
% Hello World
CENTR
ROT
PSTK
LEAV
PSTK
""";

const String CPC_CODE = """\
# Reverse the Instructions of the Program
CPC # Copy program to the Stack
ROT # Reverse the Stack
EFLP # Flip each Pair
PSTK # Print the Stack
""";

main() async {
  window.onMessage.listen((MessageEvent event) async {
    var data = event.data;

    if (data["program"] != null) {
      await execute(data["program"], data["verbose"]);
    }
  });

  window.postMessage({
    "instructions": INST_NAMES.values.toList()
  }, "*");

  window.postMessage({
    "examples": {
      "Countdown": COUNTDOWN_CODE,
      "Fibonacci Sequence": FIB,
      "Stacks": STACKS_CODE,
      "Program Code": CPC_CODE
    }
  }, "*");

  window.postMessage({
    "reference": REFERENCE
  }, "*");
}

execute(String input, bool verbose) async {
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

  vm.verbose = verbose;
  try {
    await vm.exec(program);
  } catch (e, stack) {
    await vm.printFunction("VM Error: " + e.toString() + "\n" + stack.toString() + "\n");
  }
}
