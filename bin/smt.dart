import "dart:io";
import "dart:math";

import "package:sm/vm.dart";
import "package:sm/smt.dart";
import "package:sm/io.dart";

Random random = new Random();

main(List<String> args) async {
  if (args.length != 1) {
    print("Usage: smt <program>");
    exit(1);
  }

  var file = new File(args[0]);
  List<int> prog = parseTextualProgram(file.readAsStringSync());

  var vm = new SM();
  var io = new SMIO(vm);
  await io.setup();

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

  await io.teardown();
}
