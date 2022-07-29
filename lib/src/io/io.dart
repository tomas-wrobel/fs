/// Native-based file system.
/// ==========================
/// Just re-export the supported classes from the `dart:io` library.
/// 
/// {@macro fs.support}
/// 
/// The support for these methods is planned for the future.
/// The [Directory.createTemp] will use [window.sessionStorage] to store the temporary files.
library fs.io;

export 'dart:io' show 
	File, FileSystemEntity, FileSystemEntityType, FileStat, 
	FileMode, FileSystemEvent, FileSystemException, Directory,  
	FileSystemCreateEvent, FileSystemDeleteEvent, FileSystemMoveEvent;

import 'package:path_provider/path_provider.dart' as pp;
import 'dart:io' show Directory;
import '../stub.dart' as uber;

class _FileSystemUtils implements uber.FileSystemUtils {
	_FileSystemUtils();

	@override
	Future<Directory> getApplicationDocumentsDirectory() {
		return pp.getApplicationDocumentsDirectory();
	}
}

final utils = _FileSystemUtils();