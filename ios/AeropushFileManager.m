#import "AeropushFileManager.h"

#if __has_include(<SSZipArchive/SSZipArchive.h>)
#import <SSZipArchive/SSZipArchive.h>
#define HAS_SSZIPARCHIVE 1
#elif __has_include("SSZipArchive.h")
#import "SSZipArchive.h"
#define HAS_SSZIPARCHIVE 1
#else
#define HAS_SSZIPARCHIVE 0
#endif

@implementation AeropushFileManager

+ (BOOL)deleteAtPath:(NSString *)path {
    if (!path || path.length == 0) {
        return NO;
    }

    NSFileManager *fm = [NSFileManager defaultManager];
    if (![fm fileExistsAtPath:path]) {
        return YES; // Already doesn't exist
    }

    NSError *error;
    BOOL result = [fm removeItemAtPath:path error:&error];
    if (!result) {
        NSLog(@"[Aeropush] Error deleting at path %@: %@", path, error.localizedDescription);
    }
    return result;
}

+ (BOOL)moveFromPath:(NSString *)source toPath:(NSString *)destination {
    if (!source || !destination) {
        return NO;
    }

    NSFileManager *fm = [NSFileManager defaultManager];

    // Remove destination if it exists
    if ([fm fileExistsAtPath:destination]) {
        [self deleteAtPath:destination];
    }

    // Ensure parent directory exists
    NSString *parentDir = [destination stringByDeletingLastPathComponent];
    [self createDirectoryAtPath:parentDir];

    NSError *error;
    BOOL result = [fm moveItemAtPath:source toPath:destination error:&error];

    if (!result) {
        NSLog(@"[Aeropush] Move failed from %@ to %@: %@. Attempting copy+delete fallback.",
              source, destination, error.localizedDescription);

        // Fallback: copy + delete
        result = [self copyDirectoryFromPath:source toPath:destination];
        if (result) {
            [self deleteAtPath:source];
        }
    }

    return result;
}

+ (BOOL)copyDirectoryFromPath:(NSString *)source toPath:(NSString *)destination {
    if (!source || !destination) {
        return NO;
    }

    NSFileManager *fm = [NSFileManager defaultManager];

    // Remove destination if it exists
    if ([fm fileExistsAtPath:destination]) {
        [self deleteAtPath:destination];
    }

    // Ensure parent directory exists
    NSString *parentDir = [destination stringByDeletingLastPathComponent];
    [self createDirectoryAtPath:parentDir];

    NSError *error;
    BOOL result = [fm copyItemAtPath:source toPath:destination error:&error];

    if (!result) {
        NSLog(@"[Aeropush] Error copying from %@ to %@: %@", source, destination, error.localizedDescription);
    }
    return result;
}

+ (BOOL)fileExistsAtPath:(NSString *)path {
    if (!path) return NO;
    return [[NSFileManager defaultManager] fileExistsAtPath:path];
}

+ (BOOL)directoryExistsAtPath:(NSString *)path {
    if (!path) return NO;
    BOOL isDir = NO;
    BOOL exists = [[NSFileManager defaultManager] fileExistsAtPath:path isDirectory:&isDir];
    return exists && isDir;
}

+ (BOOL)createDirectoryAtPath:(NSString *)path {
    if (!path) return NO;

    NSFileManager *fm = [NSFileManager defaultManager];
    if ([fm fileExistsAtPath:path]) {
        return YES;
    }

    NSError *error;
    BOOL result = [fm createDirectoryAtPath:path
                withIntermediateDirectories:YES
                                 attributes:nil
                                      error:&error];
    if (!result) {
        NSLog(@"[Aeropush] Error creating directory at %@: %@", path, error.localizedDescription);
    }
    return result;
}

+ (unsigned long long)fileSizeAtPath:(NSString *)path {
    if (!path) return 0;

    NSError *error;
    NSDictionary *attrs = [[NSFileManager defaultManager] attributesOfItemAtPath:path error:&error];
    if (error) return 0;
    return [attrs fileSize];
}

+ (BOOL)clearDirectoryAtPath:(NSString *)path {
    if (!path) return NO;

    NSFileManager *fm = [NSFileManager defaultManager];
    NSError *error;
    NSArray *contents = [fm contentsOfDirectoryAtPath:path error:&error];
    if (error) return NO;

    BOOL success = YES;
    for (NSString *item in contents) {
        NSString *itemPath = [path stringByAppendingPathComponent:item];
        if (![fm removeItemAtPath:itemPath error:&error]) {
            NSLog(@"[Aeropush] Error clearing item %@: %@", itemPath, error.localizedDescription);
            success = NO;
            error = nil;
        }
    }
    return success;
}

+ (BOOL)unzipFileAtPath:(NSString *)sourcePath toDestination:(NSString *)destinationPath {
    if (!sourcePath || !destinationPath) {
        return NO;
    }

#if HAS_SSZIPARCHIVE
    // Ensure destination exists
    [self createDirectoryAtPath:destinationPath];

    NSError *error;
    BOOL result = [SSZipArchive unzipFileAtPath:sourcePath
                                  toDestination:destinationPath
                                      overwrite:YES
                                       password:nil
                                          error:&error];

    if (!result || error) {
        NSLog(@"[Aeropush] Error unzipping %@ to %@: %@",
              sourcePath, destinationPath,
              error ? error.localizedDescription : @"Unknown error");
        return NO;
    }

    return YES;
#else
    NSLog(@"[Aeropush] SSZipArchive not available. Cannot unzip files.");
    return NO;
#endif
}

@end
