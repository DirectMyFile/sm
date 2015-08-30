library sm.smt;

import "dart:typed_data";

import "vm.dart";

List<int> parseTextualProgram(String input) {
  var lines = input.split("\n")
    .map((x) => x.trim())
    .where((x) => x.isNotEmpty && !x.startsWith("#"))
    .map((x) => x.split("#").first.trim())
    .toList();

  var insts = [];

  Map<String, List<String>> macros = {};

  var isInMacro = false;
  var mlines = [];
  var cmn = "";
  var i = 0;
  while (i < lines.length) {
    var line = lines[i];

    if (line.startsWith("% ")) {
      var str = line.substring(2);
      for (var cu in str.codeUnits) {
        insts.add(INST_PSH);
        insts.add(cu);
      }

      insts.add(INST_PSH);
      insts.add(str.codeUnits.length);
      i++;
      continue;
    }

    if (isInMacro && !line.startsWith(".")) {
      mlines.add(line);
      i++;
      continue;
    }

    var parts = line.split(" ").toList();

    if (parts[0].startsWith(".")) {
      var name = parts[0].substring(1);

      if (isInMacro) {
        macros[cmn] = mlines;
        mlines = [];
        isInMacro = false;
      } else {
        if (name.isEmpty) {
          throw new Exception("Invalid Macro State");
        }
        isInMacro = true;
        cmn = name;
      }
      i++;
      continue;
    }

    if (parts[0].startsWith("@")) {
      var name = parts[0].substring(1);
      if (!macros.containsKey(name)) {
        throw new Exception("Unknown Macro: ${name}");
      }
      lines.insertAll(i + 1, macros[name]);
      i++;
      continue;
    }

    for (var i = 0; i < parts.length; i++) {
      var p = parts[i];
      if (p.startsWith("~")) {
        var n = p.substring(1);
        parts[i] = INST_NAMES.keys.firstWhere((x) => INST_NAMES[x] == n.toUpperCase(), orElse: () {
          throw new Exception("Unknown Instruction: ${n}");
        }).toString();
      }
    }

    var inst = int.parse(parts[0], onError: (s) => null);
    if (inst == null) {
      inst = INST_NAMES.keys.firstWhere((x) => INST_NAMES[x] == parts[0].toUpperCase(), orElse: () {
        throw new Exception("Unknown Instruction: ${parts[0]}");
      });
    }

    insts.add(inst);
    if (parts.length == 2) {
      insts.add(int.parse(parts[1]));
    } else {
      insts.add(null);
    }
    i++;
  }

  return insts;
}

int _bytesToInteger(List<int> bytes) {
  Uint8List list = new Uint8List(4);
  list[0] = bytes[0];
  list[1] = bytes[1];
  list[2] = bytes[2];
  list[3] = bytes[3];
  return list.buffer.asByteData().getInt32(0);
}

List<int> decodeProgram(List<int> input) {
  var i = 0;
  var prog = [];
  while (true) {
    var parts = input.skip(i).take(4).toList();
    prog.add(_bytesToInteger(parts));
    i += 4;

    if (i >= input.length) {
      break;
    }
  }
  return prog;
}

String prettyPrint(List<int> program) {
  var buff = new StringBuffer();
  var i = 0;
  while (i < program.length) {
    var parts = program.skip(i).take(INSTR_SIZE).toList();
    buff.writeln("${INST_NAMES[parts[0]]} ${parts.skip(1).join(" ")}".trim());
    i += INSTR_SIZE;
  }
  return buff.toString();
}

List<int> encodeProgram(List<int> input) {
  var data = new ByteData(4 * input.length);

  var counter = 0;
  for (var n in input) {
    data.setInt32(counter * 4, n);
    counter++;
  }
  return data.buffer.asUint8List();
}
