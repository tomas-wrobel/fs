import "package:fs/html.dart" if (dart.library.io) "package:fs/io.dart";

void main() {
  File file = new File("example.txt");
  file.writeAsStringSync("Hello, World!");

  Directory dir = new Directory("example");
  dir.createSync();
}
