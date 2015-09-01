library sm.vm;

import "dart:async";

const int INST_HLT = 1; // Halt Program
const int INST_PSH = 2; // Push Value to Stack
const int INST_POP = 3; // Pop Value from Stack
const int INST_ADD = 4; // Add last 2 values on the stack and push the value to the stack
const int INST_JMP = 5; // Jump Instructions
const int INST_DUP = 6; // Duplicate Last Stack Value
const int INST_JIE = 7; // Jump if Equal
const int INST_JINE = 8; // Jump if Not Equal
const int INST_PRNT = 9; // Print Last Stack Value
const int INST_FLP = 10; // Flip
const int INST_ROT = 11; // Rotate
const int INST_OIEE = 12; // One if Either Equal
const int INST_SUB = 13; // Subtract
const int INST_SIZ = 14; // Size of Stack
const int INST_PSTK = 15; // Print Stack
const int INST_SRV = 16; // Set Register Value
const int INST_CRS = 17; // Copy Register Value to Stack
const int INST_ENTR = 18; // Create and Enter New Stack
const int INST_SHFT = 19; // Shift Stack
const int INST_RSET = 20; // Reset Program
const int INST_LEAV = 21; // Leave the Current Stack
const int INST_MULT = 22; // Multiply
const int INST_NOP = 23; // Do Nothing
const int INST_EVAL = 24; // Evaluate the Current Stack as a Program
const int INST_CLR = 25; // Clear the Stack
const int INST_SYSC = 26; // Make a System Call
const int INST_CPC = 27; // Copy Program Code to Stack
const int INST_SDUP = 28; // Duplicate Entire Stack
const int INST_EFLP = 29; // Flip Every Pair of Stack Values
const int INST_FRK = 30; // Fork a Virtual Thread
const int INST_SPI = 31; // Set Program Instruction
const int INST_CENTR = 32; // Copy Current Stack to a New Stack and Enter It

const int INSTR_SIZE = 2;

const Map<int, String> INST_NAMES = const {
  INST_HLT: "HLT",
  INST_PSH: "PSH",
  INST_POP: "POP",
  INST_ADD: "ADD",
  INST_JMP: "JMP",
  INST_DUP: "DUP",
  INST_JIE: "JIE",
  INST_JINE: "JINE",
  INST_PRNT: "PRNT",
  INST_FLP: "FLP",
  INST_ROT: "ROT",
  INST_OIEE: "OIEE",
  INST_SUB: "SUB",
  INST_SIZ: "SIZ",
  INST_PSTK: "PSTK",
  INST_SRV: "SRV",
  INST_CRS: "CRS",
  INST_SHFT: "SHFT",
  INST_RSET: "RSET",
  INST_LEAV: "LEAV",
  INST_MULT: "MULT",
  INST_NOP: "NOP",
  INST_EVAL: "EVAL",
  INST_ENTR: "ENTR",
  INST_CLR: "CLR",
  INST_SYSC: "SYSC",
  INST_CPC: "CPC",
  INST_SDUP: "SDUP",
  INST_EFLP: "EFLP",
  INST_FRK: "FRK",
  INST_SPI: "SPI",
  INST_CENTR: "CENTR"
};

typedef void SysCall(SMState sm);

class SMState {
  final SM sm;
  int pc;
  List<int> program;

  SMState(this.sm, this.pc, this.program);

  int pop() => sm.pop();
  void push(int x) => sm.push(x);

  void setRegister(int n, int v) {
    sm.registers[n] = v;
  }

  int getRegister(int n) => sm.registers[n];
}

class SM {
  List<int> stack = [];
  List<List<int>> stacks = [];
  Map<int, int> registers = {};
  Map<int, SysCall> syscalls = {};

  Function printFunction = (input) {
    print(input);
  };

  bool verbose = const bool.fromEnvironment("verbose", defaultValue: false);
  bool concurrent = identical(0, 0.0);

  exec(List<int> program, [int pc = 0]) async {
    try {
      threadCount++;

      var thread = threadCount;
      var ic = program.skip(pc).length ~/ 2;

      if (verbose) {
        printFunction("(Thread #${thread} Started, ${ic} instruction${ic > 1 ? "s" : ''})");
      }

      for (var i = 0; i < program.length; i++) {
        if (program[i] == null) {
          program[i] = 0;
        }
      }

      var running = true;

      status() {
        if (verbose) {
          var stm = stack.take(30).join(", ");
          if (stack.length > 30) {
            stm += "...";
          }

          var buff = new StringBuffer("(Thread #${thread}, ");
          inf(String key, value, [bool x = true]) {
            buff.write("${key}: ${value}");
            if (x) {
              buff.write(", ");
            }
          }
          inf("Thread Count", threadCount);
          inf("Program Counter", pc ~/ 2);
          inf("Stack Size", stack.length, false);
          buff.write(") -> (${stm})");
          printFunction(buff.toString());
        }
      }

      void jmp(int instn) {
        if (instn != 0) {
          instn = instn * INSTR_SIZE;
        }

        status();

        pc = instn;
      }

      var inst = null;
      var extra = null;

      iloop: while (running) {
        if (concurrent) {
          await new Future.delayed(Duration.ZERO);
        }

        try {
          inst = program[pc];
        } catch (e) {
          running = false;
          break;
        }

        try {
          extra = program[pc + 1];
        } catch (e) {}

        if (const bool.fromEnvironment("pinsts", defaultValue: false)) {
          var l = [inst, extra == null ? 0 : extra];
          l[0] = INST_NAMES[l[0]];
          l[1] = l[0] == "PSH" ? l[1] : "";
          printFunction("(Thread #${thread}) -> ${l.join(" ").trim()}");
        }

        switch (inst) {
          case INST_HLT:
            running = false;
            break;
          case INST_PSH:
            push(extra);
            break;
          case INST_CRS:
            var regn = pop();
            push(registers[regn]);
            break;
          case INST_SDUP:
            stack.addAll(stack.toList());
            break;
          case INST_ENTR:
            stacks.add(stack);
            stack = new List<int>();
            break;
          case INST_SRV:
            var regn = pop();
            var val = pop();
            registers[regn] = val;
            break;
          case INST_ADD:
            push(pop() + pop());
            break;
          case INST_EFLP:
            var flipped = [];

            for (var i = 0; i < stack.length; i += 2) {
              if (i + 1 != stack.length) {
                flipped.add(stack[i + 1]);
              }
              flipped.add(stack[i]);
            }

            stack = flipped;

            break;
          case INST_SUB:
            var l = pop();
            push(pop() - l);
            break;
          case INST_CLR:
            stack.clear();
            break;
          case INST_JMP:
            jmp(pop());
            continue iloop;
            break;
          case INST_SYSC:
            var cn = pop();
            if (!syscalls.containsKey(cn)) {
              throw new Exception("Unknown System Call: ${cn}");
            }
            var state = new SMState(this, pc, program);
            await syscalls[cn](state);
            program = state.program;
            var oldPc = pc;
            pc = state.pc;
            if (pc != oldPc) {
              continue iloop;
            }
            break;
          case INST_NOP:
            break;
          case INST_MULT:
            push(pop() * pop());
            break;
          case INST_RSET:
            stack.clear();
            stacks.clear();
            registers.clear();
            jmp(0);
            continue iloop;
            break;
          case INST_CENTR:
            var ns = new List<int>.from(stack);
            stacks.add(stack);
            stack = ns;
            break;
          case INST_FLP:
            var x = pop();
            var y = pop();
            push(x);
            push(y);
            break;
          case INST_POP:
            pop();
            break;
          case INST_EVAL:
            exec(stack);
            break;
          case INST_SHFT:
            var val = pop();
            stack.insert(0, val);
            break;
          case INST_SIZ:
            push(stack.length);
            break;
          case INST_JINE:
            var instn = pop();
            if (pop() != pop()) {
              jmp(instn);
              continue iloop;
            }
            break;
          case INST_DUP:
            var result = pop();
            push(result);
            push(result);
            break;
          case INST_CPC:
            stack.addAll(program);
            break;
          case INST_ROT:
            stack = stack.reversed.toList();
            break;
          case INST_OIEE:
            var left = pop();
            var right = pop();
            var of = pop();
            push((left == of || right == of) ? 1 : 0);
            break;
          case INST_JIE:
            var instn = pop();
            if (pop() == pop()) {
              jmp(instn);
              continue iloop;
            }
            break;
          case INST_PSTK:
            printFunction(stack);
            break;
          case INST_FRK:
            exec(program, pc + 2);
            concurrent = true;
            break;
          case INST_LEAV:
            var rst = stacks.removeLast();
            stack = rst;
            break;
          case INST_PRNT:
            printFunction(pop());
            break;
          case INST_SPI:
            program[pop()] = pop();
            break;
        }

        status();

        pc += INSTR_SIZE;
      }
      threadCount--;
      if (verbose) {
        printFunction("(Thread #${thread} Complete)");
      }
    } on SMError catch (e) {
      e.pc = pc ~/ INSTR_SIZE;
      rethrow;
    }
  }

  int threadCount = 0;

  void loadState(Map input) {
    stack = input["stack"];
    stacks = input["stacks"];
    registers = input["registers"];
  }

  Map saveState() => {
    "stack": stack,
    "stacks": stacks,
    "registers": registers
  };

  void push(int x) => stack.add(x);

  int pop() {
    try {
      return stack.removeLast();
    } catch (e) {
      throw new SMError("Stack is Empty");
    }
  }
}

class SMError {
  String msg;
  int pc;

  SMError(this.msg);

  @override
  toString() {
    if (pc != null) {
      return "VM Error at program counter ${pc}: ${msg}";
    } else {
      return "VM Error: ${msg}";
    }
  }
}
