#import <Foundation/Foundation.h>

typedef void (^AeropushDownloadCompletion)(NSString * _Nullable filePath, NSError * _Nullable error);
typedef void (^AeropushDownloadProgress)(float progress);

@interface AeropushFileDownloader : NSObject

/// Download a file from URL to a temporary location.
/// @param urlString The URL to download from.
/// @param destinationDir The directory to save the downloaded file in.
/// @param filename The filename to save as.
/// @param progress Progress callback (0.0 - 1.0).
/// @param completion Completion callback with file path or error.
+ (void)downloadFromURL:(NSString *)urlString
       toDirectory:(NSString *)destinationDir
          filename:(NSString *)filename
          progress:(AeropushDownloadProgress _Nullable)progress
        completion:(AeropushDownloadCompletion)completion;

/// Download and unzip a bundle from URL.
/// @param urlString The URL to download from.
/// @param destinationDir The directory to unzip into.
/// @param expectedHash Expected hash for validation (can be nil to skip).
/// @param completion Completion callback with unzipped directory path or error.
+ (void)downloadAndUnzipFromURL:(NSString *)urlString
               toDirectory:(NSString *)destinationDir
              expectedHash:(NSString * _Nullable)expectedHash
                completion:(AeropushDownloadCompletion)completion;

@end
