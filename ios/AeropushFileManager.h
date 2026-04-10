#import <Foundation/Foundation.h>

@interface AeropushFileManager : NSObject

/// Delete a file or directory at path.
+ (BOOL)deleteAtPath:(NSString *)path;

/// Move file/directory from source to destination. Falls back to copy+delete if move fails.
+ (BOOL)moveFromPath:(NSString *)source toPath:(NSString *)destination;

/// Recursively copy directory contents from source to destination.
+ (BOOL)copyDirectoryFromPath:(NSString *)source toPath:(NSString *)destination;

/// Check if a file exists at path.
+ (BOOL)fileExistsAtPath:(NSString *)path;

/// Check if a directory exists at path.
+ (BOOL)directoryExistsAtPath:(NSString *)path;

/// Create directory at path, including intermediate directories.
+ (BOOL)createDirectoryAtPath:(NSString *)path;

/// Get file size in bytes.
+ (unsigned long long)fileSizeAtPath:(NSString *)path;

/// Clear contents of a directory without deleting the directory itself.
+ (BOOL)clearDirectoryAtPath:(NSString *)path;

/// Unzip a file from sourcePath to destinationPath using SSZipArchive.
+ (BOOL)unzipFileAtPath:(NSString *)sourcePath toDestination:(NSString *)destinationPath;

@end
