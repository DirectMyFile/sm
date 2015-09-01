import "dart:async";
import "dart:io";
import "dart:isolate";

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
    outFile = await outFile.rename("${Directory.current.path}/out.dart");

    if (args.contains("--snapshot")) {
      await generateSnapshotFile("${Directory.current.path}/out.snapshot", outFile.path);
      await outFile.delete();
      outFile = new File(outFile.path.replaceAll(".dart", ".snapshot"));
    }

    if (args.contains("--run")) {
      var isolate = await Isolate.spawnUri(outFile.uri, [], null);
      await outFile.delete();
      var port = new ReceivePort();
      isolate.addOnExitListener(port.sendPort);
      await port.first;
    }

    await dir.delete(recursive: true);
  }
}

const String TEMPLATE = r"""
import "package:sm/vm.dart";
import "package:sm/io.dart";

final List<int> program = [
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

Future generateSnapshotFile(String target, String input) async {
  var result = await Process.run(getDartExecutable(), [
    "--snapshot=${target}",
    input
  ]);

  if (result.exitCode != 0) {
    throw new Exception("Failed to generate snapshot for ${input}.");
  }
}

String getDartExecutable() {
  String dartExe;
  try {
    dartExe = Platform.resolvedExecutable;
  } catch (e) {
    dartExe = Platform.executable.isNotEmpty ? Platform.executable : "dart";
  }
  return dartExe;
}
