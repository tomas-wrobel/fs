# Vise File System
This file system is for Dart & Flutter users, who wants cross-platform API

## Features
* cross-platform, working on web!
* open to anyone
	* you may need to fork the repo and customize it
	* unlike Vise Maps themselves, this code is licensed under 3 clauses, which give you much more freedom
* uses the same API as `dart:io`


## Getting started
First install:

```sh
$ dart pub add fs
```

or

```sh
$ flutter pub add fs
```

And then a little bit complicated import:
```dart
import 'package:fs/io.dart' if (dart.library.html) 'package:fs/html.dart';
```

or the opposite way:

```dart
import 'package:fs/html.dart' if (dart.library.io) 'package:fs/io.dart';
```

## Aditional information
This package was created because I needed some cross-platform solution for our [future app](https://github.com/vise-maps/app).
I found [universal_io](https://pub.dev/packages/universal_io). But there are two issues: the package does not seem to be
mantained, and mainly &ndash; it does not work (on web). There are opened issues for a year without a response.

Also that package has just copied code from Dart SDK (and has used `IOOverrides`) which is the worst possible way to use localStorage I would say:

1. Dart SDK changes almost everyday and after a stable release, the code must be re-copied and re-edited
2. The code will be big because of the `dart:io` library size. Why to include it twice?

Well, I encourage you to fork this package, come with wider support; and meanwhile, I'll try to get some answers from the maintainers of `universal_io`.