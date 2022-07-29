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

I do not recommend the opposite way:

```dart
// BAD
import 'package:fs/html.dart' if (dart.library.io) 'package:fs/io.dart';
```

for two reason:
1. It won't import documentation in your IDE, because the `html.dart` is not documented, since it mirrors `dart:io`
2. It will import types incompatible with the original ones. An example:


## Additional information

TODO: Tell users more about the package: where to find more information, how to 
contribute to the package, how to file issues, what response they can expect 
from the package authors, and more.
