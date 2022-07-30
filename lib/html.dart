/// Web-based file system
/// ====================
/// It uses [window.localStorage] to store the files.
/// Each file is stored as a string - the content of the file.
/// The file path is the key of the localStorage.
/// 
/// It reflects the `dart:io` library. However, it's not the copy of that like `universal_io`.
/// But unlike that package, it works! And it does not use the code of Dart team, which changes over time.
/// 
/// {@template fs.support}
/// # Supported classes
/// * [File]
/// * [FileSystemEntity]
/// * [FileSystemEntityType]
/// * [FileStat]
/// * [FileMode],
/// * [FileSystemEvent]
/// * [FileSystemException]
/// * [Directory]
/// 
/// ## Unsupported methods
/// * [FileSystemEntity.resolveSymbolicLinks]
/// * [FileSystemEntity.resolveSymbolicLinksSync],
/// * [Directory.createTemp]
/// * [Directory.createTempSync]
/// {@endtemplate}
/// 
/// The support for these methods is planned for the future.
/// The [Directory.createTemp] will use [window.sessionStorage] to store the temporary files.
/// 
/// ## Tip
/// If you plan to use these library only for web, consider using synchronous methods.
/// For example, [FileSystemEntity.typeSync] instead of [FileSystemEntity.type].
/// The [window.localStorage] is synchronous, so it's faster. 
/// 
/// However, if you plan to use these library for both web and mobile,
/// consider using asynchronous methods. They are more efficient.
library fs.html;


import 'io.dart' if (dart.library.html) 'src/io_empty.dart' as uber;
import 'dart:typed_data';
import 'dart:convert';
import 'dart:async';
import 'dart:html';

Uri _current = Uri.parse('/');

abstract class FileSystemEntity implements uber.FileSystemEntity {
	@override
	final Uri uri;
	late final _controller = StreamController<FileSystemEvent>.broadcast(
		onListen: () {
			_shouldEmit = true;
		},
		onCancel: () {
			_shouldEmit = false;
		},
	);
	int? _emitType;
	bool _shouldEmit = false;
	FileSystemEntity(this.uri);

	static get isWatchSupported => true;

	static bool isFileSync(String path) => typeSync(path) == FileSystemEntityType.file;
	static bool isDirectorySync(String path) => typeSync(path) == FileSystemEntityType.directory;
	static bool isLinkSync(String path) => typeSync(path) == FileSystemEntityType.link;

	static Future<bool> isFile(String path) => Future.value(isFileSync(path));
	static Future<bool> isDirectory(String path) => Future.value(isDirectorySync(path));
	static Future<bool> isLink(String path) => Future.value(isLinkSync(path));

	static FileSystemEntityType typeSync(String path) {
		switch (window.localStorage['${_current.resolve(path)}']) {
			case '{dir}': return FileSystemEntityType.directory;
			case null: return FileSystemEntityType.notFound;
			default: return FileSystemEntityType.file;
		}
	}

	@override
	Future<bool> exists() {
		return Future.value(existsSync());
	}

	@override
	bool existsSync() {
		return window.localStorage['${absolute.uri}'] != null;
	}

	@override
	bool get isAbsolute => uri.isAbsolute;

	@override
	Directory get parent {
		final segments = uri.pathSegments;
		if (segments.isEmpty || (segments.first == '' && segments.length == 1)) {
			throw FileSystemException('Cannot get parent of root directory');
		}
		return Directory(segments.take(segments.length - 1).join('/'));
	}

	@override
	String get path => '$uri';

	@override
	Future<FileSystemEntity> rename(String newPath) {
		return Future.value(renameSync(newPath));
	}

	@override
	FileSystemEntity renameSync(String newPath);

	Future<FileSystemEntity> create({bool recursive = false}) {
		return Future.value(createSync(recursive: recursive));
	}

	FileSystemEntity createSync({bool recursive = false}) {
		if (window.localStorage[_statKey] == null) {
			final now = DateTime.now();
			_stat("accessed", now);
			_stat("modified", now);
			_stat("changed", now);
		}
		return this;
	}

	@override
	Future<String> resolveSymbolicLinks() {
		throw UnsupportedError('Not supported on web');
	}

	@override
	String resolveSymbolicLinksSync() {
		throw UnsupportedError('Not supported on web');
	}

	@override
	Future<FileStat> stat() {
		return Future.value(statSync());
	}

	@override
	FileStat statSync() {
		final Map<String, dynamic> map = json.decode(window.localStorage[_statKey]!);
		return FileStat._(
			DateTime.parse(map['accessed']),
			DateTime.parse(map['changed']),
			map['mode'],
			DateTime.parse(map['modified']),
			_size,
			this is Directory ? FileSystemEntityType.directory : FileSystemEntityType.file,
		);
	}

	int get _size;

	@override
	Stream<FileSystemEvent> watch({int events = FileSystemEvent.all, bool recursive = false}) {
		_emitType = events;
		return _controller.stream;
	}
	
	@override
	Future<FileSystemEntity> delete({bool recursive = false}) {
		return Future.value(deleteSync(recursive: recursive));
	}
	
	@override
	FileSystemEntity deleteSync({bool recursive = false});

	void _emit(int type) {
		switch (type) {
			case FileSystemEvent.create:
		}
		if (_emitType == type && _shouldEmit) {
			switch (type) {
				case FileSystemEvent.create: {
					_controller.add(FileSystemCreateEvent._(path, this is Directory));
					break;
				}
				case FileSystemEvent.delete: {
					_controller.add(FileSystemDeleteEvent._(path, this is Directory));
					break;
				}
				case FileSystemEvent.modify: {
					_controller.add(FileSystemModifyEvent._(path, this is Directory));
					break;
				}
				case FileSystemEvent.move: {
					_controller.add(FileSystemMoveEvent._(path, this is Directory));
					break;
				}
				default: {
					_controller.add(FileSystemEvent._(type, path, this is Directory));
				}
			}
		}
	}

	void _stat(String type, [DateTime? date]) {
		final dateOrNow = date ?? DateTime.now();
		final Map<String, dynamic> stat = json.decode(
			window.localStorage[_statKey] ?? '{}',
		);
		window.localStorage[_statKey] = json.encode({
			...stat, 
			type: '$dateOrNow'
		});
		try {
			parent._stat(type, dateOrNow);
		} catch (e) {
			// no parent
		}
	}

	String get _statKey {
		return Uri(scheme: 'stat', path: absolute.uri.path).toString();
	}
}

enum FileMode implements uber.FileMode {
	read,
	write,
	append,
	writeOnly,
	writeOnlyAppend,
}

class FileSystemEvent implements uber.FileSystemEvent {
	/// Bitfield for [FileSystemEntity.watch], to enable [FileSystemCreateEvent]s.
	static const int create = 1 << 0;

	/// Bitfield for [FileSystemEntity.watch], to enable [FileSystemModifyEvent]s.
	static const int modify = 1 << 1;

	/// Bitfield for [FileSystemEntity.watch], to enable [FileSystemDeleteEvent]s.
	static const int delete = 1 << 2;

	/// Bitfield for [FileSystemEntity.watch], to enable [FileSystemMoveEvent]s.
	static const int move = 1 << 3;

	/// Bitfield for [FileSystemEntity.watch], for enabling all of [create],
	/// [modify], [delete] and [move].
	static const int all = create | modify | delete | move;

	/// The type of event. See [FileSystemEvent] for a list of events.
	@override
	final int type;

	/// The path that triggered the event.
	///
	/// Depending on the platform and the [FileSystemEntity], the path may be
	/// relative.
	@override
	final String path;

	/// Is `true` if the event target was a directory.
	///
	/// Note that if the file has been deleted by the time the event has arrived,
	/// this will always be `false` on Windows. In particular, it will always be
	/// `false` for `delete` events.
	@override
	final bool isDirectory;

	FileSystemEvent._(this.type, this.path, this.isDirectory);
}

class FileSystemCreateEvent extends FileSystemEvent {
	FileSystemCreateEvent._(String path, bool isDirectory) : super._(FileSystemEvent.create, path, isDirectory);
}

class FileSystemDeleteEvent extends FileSystemEvent {
	FileSystemDeleteEvent._(String path, bool isDirectory) : super._(FileSystemEvent.delete, path, isDirectory);
}

class FileSystemMoveEvent extends FileSystemEvent {
	FileSystemMoveEvent._(String path, bool isDirectory) : super._(FileSystemEvent.move, path, isDirectory);
}

class FileSystemModifyEvent extends FileSystemEvent {
	FileSystemModifyEvent._(String path, bool isDirectory) : super._(FileSystemEvent.modify, path, isDirectory);
}

class FileSystemException implements Exception, uber.FileSystemException {
	@override
	final String message;

	@override
	final String? path;

	FileSystemException([this.message = "", this.path = ""]);

	@override
	Null get osError => null;
}

enum FileSystemEntityType implements uber.FileSystemEntityType {
	file,
	directory,
	link,
	notFound;

	@override
	String toString() {
		switch (this) {
			case FileSystemEntityType.file:
				return 'file';
			case FileSystemEntityType.directory:
				return 'directory';
			case FileSystemEntityType.link:
				return 'link';
			case FileSystemEntityType.notFound:
				return 'notFound';
		}
	}
}

class FileStat implements uber.FileStat {
	@override
	final DateTime accessed;

	@override
	final DateTime changed;

	@override
	final int mode;

	@override
	final DateTime modified;

	@override
	final int size;

	@override
	final FileSystemEntityType type;

	@override
	String modeString() {
		var permissions = mode & 0xFFF;
		const codes = [
			'---', '--x', '-w-', '-wx', 
			'r--', 'r-x', 'rw-', 'rwx',
		];
		return [
			if ((permissions & 0x800) != 0) "(suid) ",
			if ((permissions & 0x400) != 0) "(guid) ",
			if ((permissions & 0x200) != 0) "(sticky) ",
			codes[(permissions >> 6) & 0x7],
			codes[(permissions >> 3) & 0x7],
			codes[permissions & 0x7]
		].join();
	}
	
	FileStat._(
		this.accessed,
		this.changed,
		this.mode,
		this.modified,
		this.size,
		this.type
	);

	Map<String, dynamic> toJson() {
		return {
			'accessed': '$accessed',
			'changed': '$changed',
			'modified': '$modified',
			'type': '$type',
			'size': '$size',
			'mode': '$mode',
		};
	}
}

class Directory extends FileSystemEntity implements uber.Directory {
	Directory(String path) : super(Uri.directory(path));
	Directory.fromUri(Uri uri) : super(uri);
	
	@override
	Directory get absolute => Directory.fromUri(_current.resolveUri(uri));

	static uber.Directory get current => Directory.fromUri(_current);

	static set current(uber.Directory value) {
		_current = _current.resolveUri(value.uri);
	}

	@override
	Future<Directory> create({bool recursive = false}) {
		return Future.value(createSync(recursive: recursive));
	}
	
	@override
	Directory createSync({bool recursive = false}) {
		super.createSync(recursive: recursive);
		if (!existsSync()) {
			if (!recursive) {
				window.localStorage['${absolute.uri}'] = '{dir}'; 
			} else {
				for (Directory dir = this; !dir.existsSync() && dir.uri.pathSegments.isNotEmpty; dir = dir.parent) {
					dir.createSync();
				}
			}
		}
		_emit(FileSystemEvent.create);
		return this;
	}

	@override
	Directory renameSync(String newPath) {
		deleteSync();
		final newDir = Directory(newPath);
		newDir.createSync();
		for (final entity in listSync()) {
			final segments = [
				...newDir.uri.pathSegments, 
				entity.uri.pathSegments.last
			];
			final newEntity = entity.renameSync(segments.join('/'));
			if (newEntity is Directory) {
				newEntity.createSync();
			}
		}
		return newDir;
	}

	@override
	Future<Directory> rename(String newPath) {
		return Future.value(renameSync(newPath));
	}
	
	@override
	Future<Directory> createTemp([String? prefix]) {
		return Future.value(createTempSync(prefix));
	}

	@override
	Directory createTempSync([String? prefix]) {
		throw UnsupportedError('Not implemented');
	}
	
	@override
	Directory deleteSync({bool recursive = false}) {
		 if (recursive) {
			window.localStorage.remove('${absolute.uri}');
			for (final entity in listSync()) {
				if (entity is Directory) {
					entity.deleteSync(recursive: true);
				} else {
					entity.deleteSync();
				}
			}
		 }
		 _emit(FileSystemEvent.delete);
		 return this;
	}
	
	@override
	Stream<FileSystemEntity> list({bool recursive = false, bool followLinks = true}) {
		 return Stream.fromIterable(listSync(recursive: recursive, followLinks: followLinks));
	}
	
	@override
	List<FileSystemEntity> listSync({bool recursive = false, bool followLinks = true}) {
		final String storageKey = _current.resolveUri(uri).toString();
		return [
			for (final key in window.localStorage.keys)
				if (
					key != storageKey && 
					key.startsWith(storageKey) && 
					Uri.tryParse(key.replaceFirst(RegExp('/\$'), ''))?.pathSegments.length == absolute.uri.pathSegments.length
				)
					if (window.localStorage[key] == '{dir}')
						Directory.fromUri(uri.resolveUri(Uri.parse(key, storageKey.length)))
					else
						File.fromUri(uri.resolveUri(Uri.parse(key, storageKey.length)))
		];
	}
	
	@override
	int get _size => listSync().fold(0, (sum, entity) => sum + entity._size);
}

class File extends FileSystemEntity implements uber.File {
	File(String path) : super(Uri.parse(path));
	File.fromUri(Uri uri) : super(uri);
	
	@override
	File get absolute => File.fromUri(_current.resolveUri(uri));
	
	@override
	Future<File> create({bool recursive = false}) {
		return Future.value(createSync(recursive: recursive));
	}
	
	@override
	File createSync({bool recursive = false}) {
		super.createSync(recursive: recursive);
		if (!recursive) {
			window.localStorage['${absolute.uri}'] = ''; 
		} else {
			for (Directory dir = parent; !dir.existsSync() && dir.uri.pathSegments.isNotEmpty; dir = dir.parent) {
				dir.createSync();
			}
		}
		return this;
	}

	@override
	File renameSync(String newPath) {
		final result = copySync(newPath);
		deleteSync();
		return result;
	}

	@override
	Future<File> rename(String newPath) {
		return Future.value(renameSync(newPath));
	}

	@override
	int get _size => readAsBytesSync().length;

	@override
	Future<File> copy(String newPath) {
		return Future.value(copySync(newPath));
	}

	@override
	File copySync(String newPath) {
		return File(newPath)
			..createSync()
			..writeAsBytesSync(readAsBytesSync())
		;
	}

	@override
	File deleteSync({bool recursive = false}) {
		window.localStorage.remove('${absolute.uri}');
		return this;
	}

	@override
	Future<DateTime> lastAccessed() {
		return stat().then((stat) => stat.accessed);
	}

	@override
	DateTime lastAccessedSync() {
		return statSync().accessed;
	}

	@override
	Future<DateTime> lastModified() {
		return Future.value(lastModifiedSync());
	}

	@override
	DateTime lastModifiedSync() {
		return statSync().modified;
	}

	@override
	Future<int> length() {
		return readAsBytes().then((bytes) => bytes.length);
	}

	@override
	int lengthSync() {
		return readAsBytesSync().length;
	}

	@override
	open({uber.FileMode mode = FileMode.read}) {
		throw UnimplementedError();
	}

	@override
	Stream<List<int>> openRead([int? start, int? end]) {
		throw UnimplementedError();
	}

	@override
	openSync({uber.FileMode mode = FileMode.read}) {
		throw UnimplementedError();
	}

	@override
	openWrite({uber.FileMode mode = FileMode.write, Encoding encoding = utf8}) {
		throw UnimplementedError();
	}

	@override
	Future<Uint8List> readAsBytes() {
		return Future.value(readAsBytesSync());
	}

	@override
	Uint8List readAsBytesSync() {
		return Uint8List.fromList(window.localStorage[uri.toString()]?.split('-').map(int.parse).toList() ?? []);
	}

	@override
	Future<List<String>> readAsLines({Encoding encoding = utf8}) {
		return readAsString(encoding: encoding).then((value) => value.split('\n'));
	}

	@override
	List<String> readAsLinesSync({Encoding encoding = utf8}) {
		return readAsStringSync().split('\n');
	}

	@override
	Future<String> readAsString({Encoding encoding = utf8}) {
		return Future.value(readAsStringSync());
	}

	@override
	String readAsStringSync({Encoding encoding = utf8}) {
		return encoding.decode(window.localStorage['${absolute.uri}']!.split('-').map(int.parse).toList());
	}

	@override
	Future setLastAccessed(DateTime time) {
		return Future(() => setLastAccessedSync(time));
	}

	@override
	void setLastAccessedSync(DateTime time) {
		_stat("accessed", time);
	}

	@override
	Future setLastModified(DateTime time) {
		return Future(() => setLastModifiedSync(time));
	}

	@override
	void setLastModifiedSync(DateTime time) {
		_stat("modified", time);
	}

	@override
	Future<File> writeAsBytes(List<int> bytes, {uber.FileMode mode = FileMode.write, bool flush = false}) {
		writeAsBytesSync(bytes, mode: mode, flush: flush);
		return Future.value(this);
	}

	@override
	void writeAsBytesSync(List<int> bytes, {uber.FileMode mode = FileMode.write, bool flush = false}) {
		window.localStorage['${absolute.uri}'] = bytes.join('-');
	}

	@override
	Future<File> writeAsString(String contents, {uber.FileMode mode = FileMode.write, Encoding encoding = utf8, bool flush = false}) async {
		return writeAsBytes(encoding.encode(contents), mode: mode, flush: flush);
	}

	@override
	void writeAsStringSync(String contents, {dynamic mode = FileMode.write, Encoding encoding = utf8, bool flush = false}) {
		writeAsBytesSync(encoding.encode(contents));
	}
}