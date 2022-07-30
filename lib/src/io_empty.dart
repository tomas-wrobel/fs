abstract class FileSystemEntity {
	String get path;
	Uri get uri;
	Future<bool> exists();
	bool existsSync();
	Future<FileSystemEntity> rename(String newPath);
	FileSystemEntity renameSync(String newPath);
	Future<String> resolveSymbolicLinks();
	String resolveSymbolicLinksSync();
	Future<FileStat> stat();
	FileStat statSync();
	Future<FileSystemEntity> delete();
	bool get isAbsolute;
	FileSystemEntity get absolute;
	Directory get parent;
	Future<FileSystemEntity> create({bool recursive = false});
	void createSync({bool recursive = false});
}

abstract class Directory implements FileSystemEntity {
	Future<Directory> createTemp([String? prefix]);
	Directory createTempSync([String? prefix]);
	Stream<FileSystemEntity> list({bool recursive = false, bool followLinks = true});
	List<FileSystemEntity> listSync({bool recursive = false, bool followLinks = true});
}

abstract class File implements FileSystemEntity {}

abstract class FileSystemEntityType {}
abstract class FileStat {
	final DateTime changed;
	final DateTime modified;
	final DateTime accessed;
	final FileSystemEntityType type;
	final int mode;
	final int size;

	FileStat._(this.changed, this.modified, this.accessed, this.type, this.mode, this.size);
}
abstract class FileMode {}
abstract class FileSystemEvent {}
abstract class FileSystemException {}
abstract class FileSystemCreateEvent extends FileSystemEvent {}
abstract class FileSystemDeleteEvent extends FileSystemEvent {}
abstract class FileSystemMoveEvent extends FileSystemEvent {}