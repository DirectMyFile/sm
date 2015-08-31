import "dart:io";

main() async {
  var file = new File("lib/vm.dart");
  var content = await file.readAsLines();
  for (var line in content) {
    if (!line.startsWith("const int INST_")) {
      continue;
    }

    var split = line.split(" ");
    var name = split[2].split("_").last;
    var p = split[4];
    var id = int.parse(p.substring(0, p.length - 1));
    var desc = split.skip(6).join(" ");
    print("${name} (${id}): ${desc}");
  }
}