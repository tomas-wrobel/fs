abstract class FileSystemUtils {
	/// Path to a directory where the application may place data that is
	/// user-generated, or that cannot otherwise be recreated by your application.
	///
	/// On iOS, this uses the `NSDocumentDirectory` API. Consider using
	/// [getApplicationSupportDirectory] instead if the data is not user-generated.
	///
	/// On Android, this uses the `getDataDirectory` API on the context. Consider
	/// using [getExternalStorageDirectory] instead if data is intended to be visible
	/// to the user.
	///
	/// Throws a `MissingPlatformDirectoryException` if the system is unable to
	/// provide the directory.
	Future getApplicationDocumentsDirectory();
}