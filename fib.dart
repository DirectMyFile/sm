import "package:sm/vm.dart";
import "package:sm/io.dart";

final List<int> program = [
  2,
  0,
  2,
  1,
  16,
  0,
  2,
  30,
  6,
  0,
  2,
  2,
  16,
  0,
  6,
  0,
  2,
  0,
  2,
  1,
  12,
  0,
  2,
  1,
  2,
  26,
  7,
  0,
  14,
  0,
  2,
  0,
  2,
  34,
  7,
  0,
  6,
  0,
  2,
  1,
  13,
  0,
  10,
  0,
  2,
  2,
  13,
  0,
  2,
  7,
  5,
  0,
  2,
  1,
  17,
  0,
  2,
  1,
  4,
  0,
  2,
  1,
  16,
  0,
  2,
  8,
  5,
  0,
  2,
  1,
  17,
  0,
  9,
  0
];

main() async {
  var vm = new SM();
  var io = new SMIO(vm);
  await io.setup();

  try {
    await vm.exec(program);
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
