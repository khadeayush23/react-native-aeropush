#import "AeropushFileDownloader.h"
#import "AeropushFileManager.h"
#import "AeropushConstants.h"
#import <CommonCrypto/CommonDigest.h>

@interface AeropushDownloadDelegate : NSObject <NSURLSessionDownloadDelegate>
@property (nonatomic, copy) NSString *destinationDir;
@property (nonatomic, copy) NSString *filename;
@property (nonatomic, copy) AeropushDownloadProgress progressCallback;
@property (nonatomic, copy) AeropushDownloadCompletion completionCallback;
@end

@implementation AeropushDownloadDelegate

- (void)URLSession:(NSURLSession *)session
      downloadTask:(NSURLSessionDownloadTask *)downloadTask
didFinishDownloadingToURL:(NSURL *)location {
    NSString *destPath = [self.destinationDir stringByAppendingPathComponent:self.filename];

    // Ensure destination directory exists
    [AeropushFileManager createDirectoryAtPath:self.destinationDir];

    // Remove existing file if any
    [AeropushFileManager deleteAtPath:destPath];

    NSError *error;
    [[NSFileManager defaultManager] moveItemAtURL:location
                                            toURL:[NSURL fileURLWithPath:destPath]
                                            error:&error];

    if (error) {
        NSLog(@"[Aeropush] Error moving downloaded file: %@", error.localizedDescription);
        if (self.completionCallback) {
            dispatch_async(dispatch_get_main_queue(), ^{
                self.completionCallback(nil, error);
            });
        }
    } else {
        if (self.completionCallback) {
            dispatch_async(dispatch_get_main_queue(), ^{
                self.completionCallback(destPath, nil);
            });
        }
    }
}

- (void)URLSession:(NSURLSession *)session
      downloadTask:(NSURLSessionDownloadTask *)downloadTask
      didWriteData:(int64_t)bytesWritten
 totalBytesWritten:(int64_t)totalBytesWritten
totalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite {
    if (self.progressCallback && totalBytesExpectedToWrite > 0) {
        float progress = (float)totalBytesWritten / (float)totalBytesExpectedToWrite;
        dispatch_async(dispatch_get_main_queue(), ^{
            self.progressCallback(progress);
        });
    }
}

- (void)URLSession:(NSURLSession *)session
              task:(NSURLSessionTask *)task
didCompleteWithError:(NSError *)error {
    if (error && self.completionCallback) {
        dispatch_async(dispatch_get_main_queue(), ^{
            self.completionCallback(nil, error);
        });
    }
}

@end

@implementation AeropushFileDownloader

+ (void)downloadFromURL:(NSString *)urlString
            toDirectory:(NSString *)destinationDir
               filename:(NSString *)filename
               progress:(AeropushDownloadProgress)progress
             completion:(AeropushDownloadCompletion)completion {
    NSURL *url = [NSURL URLWithString:urlString];
    if (!url) {
        NSError *error = [NSError errorWithDomain:@"com.aeropush"
                                             code:-1
                                         userInfo:@{NSLocalizedDescriptionKey: @"Invalid URL"}];
        if (completion) {
            completion(nil, error);
        }
        return;
    }

    AeropushDownloadDelegate *delegate = [[AeropushDownloadDelegate alloc] init];
    delegate.destinationDir = destinationDir;
    delegate.filename = filename;
    delegate.progressCallback = progress;
    delegate.completionCallback = completion;

    NSURLSessionConfiguration *config = [NSURLSessionConfiguration defaultSessionConfiguration];
    config.timeoutIntervalForRequest = 60;
    config.timeoutIntervalForResource = 300;

    NSURLSession *session = [NSURLSession sessionWithConfiguration:config
                                                          delegate:delegate
                                                     delegateQueue:nil];

    NSURLSessionDownloadTask *task = [session downloadTaskWithURL:url];
    [task resume];
}

+ (void)downloadAndUnzipFromURL:(NSString *)urlString
                    toDirectory:(NSString *)destinationDir
                   expectedHash:(NSString *)expectedHash
                     completion:(AeropushDownloadCompletion)completion {

    NSString *tempDir = [NSTemporaryDirectory() stringByAppendingPathComponent:[[NSUUID UUID] UUIDString]];
    [AeropushFileManager createDirectoryAtPath:tempDir];

    [self downloadFromURL:urlString
             toDirectory:tempDir
                filename:kAeropushDownloadZipFilename
                progress:nil
              completion:^(NSString *filePath, NSError *error) {
        if (error || !filePath) {
            [AeropushFileManager deleteAtPath:tempDir];
            if (completion) {
                completion(nil, error ?: [NSError errorWithDomain:@"com.aeropush"
                                                             code:-2
                                                         userInfo:@{NSLocalizedDescriptionKey: @"Download failed"}]);
            }
            return;
        }

        // Validate ZIP file (check magic bytes)
        if (![self isValidZipFile:filePath]) {
            [AeropushFileManager deleteAtPath:tempDir];
            NSError *zipError = [NSError errorWithDomain:@"com.aeropush"
                                                    code:-3
                                                userInfo:@{NSLocalizedDescriptionKey: @"Downloaded file is not a valid ZIP"}];
            if (completion) {
                completion(nil, zipError);
            }
            return;
        }

        // Unzip
        NSString *unzipDir = [tempDir stringByAppendingPathComponent:@"unzipped"];
        BOOL unzipped = [AeropushFileManager unzipFileAtPath:filePath toDestination:unzipDir];

        if (!unzipped) {
            [AeropushFileManager deleteAtPath:tempDir];
            NSError *unzipError = [NSError errorWithDomain:@"com.aeropush"
                                                      code:-4
                                                  userInfo:@{NSLocalizedDescriptionKey: @"Failed to unzip bundle"}];
            if (completion) {
                completion(nil, unzipError);
            }
            return;
        }

        // Clean up the zip file
        [AeropushFileManager deleteAtPath:filePath];

        // Move unzipped contents to destination
        [AeropushFileManager clearDirectoryAtPath:destinationDir];
        [AeropushFileManager createDirectoryAtPath:destinationDir];

        if ([AeropushFileManager moveFromPath:unzipDir toPath:destinationDir]) {
            [AeropushFileManager deleteAtPath:tempDir];
            if (completion) {
                completion(destinationDir, nil);
            }
        } else {
            [AeropushFileManager deleteAtPath:tempDir];
            NSError *moveError = [NSError errorWithDomain:@"com.aeropush"
                                                     code:-5
                                                 userInfo:@{NSLocalizedDescriptionKey: @"Failed to move unzipped files"}];
            if (completion) {
                completion(nil, moveError);
            }
        }
    }];
}

+ (BOOL)isValidZipFile:(NSString *)path {
    NSFileHandle *handle = [NSFileHandle fileHandleForReadingAtPath:path];
    if (!handle) return NO;

    NSData *header = [handle readDataOfLength:4];
    [handle closeFile];

    if (header.length < 4) return NO;

    const uint8_t *bytes = (const uint8_t *)header.bytes;
    // ZIP magic number: PK\x03\x04
    return (bytes[0] == 0x50 && bytes[1] == 0x4B && bytes[2] == 0x03 && bytes[3] == 0x04);
}

+ (NSString *)sha256HashOfFileAtPath:(NSString *)path {
    NSFileHandle *handle = [NSFileHandle fileHandleForReadingAtPath:path];
    if (!handle) return nil;

    CC_SHA256_CTX ctx;
    CC_SHA256_Init(&ctx);

    while (YES) {
        @autoreleasepool {
            NSData *data = [handle readDataOfLength:4096];
            if (data.length == 0) break;
            CC_SHA256_Update(&ctx, data.bytes, (CC_LONG)data.length);
        }
    }
    [handle closeFile];

    unsigned char digest[CC_SHA256_DIGEST_LENGTH];
    CC_SHA256_Final(digest, &ctx);

    NSMutableString *hash = [NSMutableString stringWithCapacity:CC_SHA256_DIGEST_LENGTH * 2];
    for (int i = 0; i < CC_SHA256_DIGEST_LENGTH; i++) {
        [hash appendFormat:@"%02x", digest[i]];
    }
    return [hash copy];
}

@end
