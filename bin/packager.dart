import "dart:io";

import "package:sm/smt.dart";

main(List<String> args) async {
  if (args.isEmpty) {
    print("Usage: packager <program>");
    exit(1);
  }

  var path = args.firstWhere((x) => !x.startsWith("--"), orElse: () => null);
  var file = new File(path);
  var content = file.readAsStringSync();
  var program = parseTextualProgram(content);

  var output = TEMPLATE.replaceAll("{{program}}", program.join(",\n  "));
  if (args.contains("--print")) {
    print(output.trim());
  } else {
    var dir = await Directory.systemTemp.createTemp("dart-sm-packager");
    dir = dir.absolute;
    var f = new File("${dir.path}/input.dart");
    await f.create(recursive: true);
    await f.writeAsString(output);
    var packageRoot = Platform.script.resolve("../packages").toFilePath();
    var result = await Process.run("dart2js", [
      "--package-root=${packageRoot}",
      f.path,
      "--output-type=dart",
      "--categories=Server",
      "-o",
      "${dir.path}/out.dart"
    ]..addAll(args.contains("--dev") ? [] : ["-m"]));

    if (result.exitCode != 0) {
      print("STDOUT:");
      print(result.stdout);
      print("STDERR:");
      print(result.stderr);
      await dir.delete(recursive: true);
      exit(1);
    }
    var outFile = new File("${dir.path}/out.dart");
    await outFile.rename("${Directory.current.path}/out.dart");
    await dir.delete(recursive: true);
  }
}

const String TEMPLATE = r"""
import "package:sm/vm.dart";
import "package:sm/io.dart";

const List<int> program = const [
  {{program}}
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
""";