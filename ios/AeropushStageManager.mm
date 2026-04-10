#import "AeropushStageManager.h"
#import "AeropushFileDownloader.h"
#import "AeropushSlotManager.h"
#import "AeropushStateManager.h"
#import "AeropushEventHandler.h"
#import "AeropushConstants.h"

@implementation AeropushStageManager

+ (void)downloadStageBundle:(NSString *)urlString
                       hash:(NSString *)hash
                 completion:(AeropushStageCompletion)completion {
    AeropushStateManager *state = [AeropushStateManager shared];
    NSString *stageDir = [state stageDirectoryPath];
    NSString *tempDownloadDir = [stageDir stringByAppendingPathComponent:@"_download_temp"];

    [[AeropushEventHandler shared] addEvent:@"STAGE_DOWNLOAD_START" payload:@{
        @"url": urlString ?: @"",
        @"hash": hash ?: @""
    }];

    [AeropushFileDownloader downloadAndUnzipFromURL:urlString
                                        toDirectory:tempDownloadDir
                                       expectedHash:hash
                                         completion:^(NSString *filePath, NSError *error) {
        if (error || !filePath) {
            NSString *errorMsg = error ? error.localizedDescription : @"Unknown download error";
            NSLog(@"[Aeropush] Stage bundle download failed: %@", errorMsg);

            [[AeropushEventHandler shared] addEvent:@"STAGE_DOWNLOAD_FAIL" payload:@{
                @"error": errorMsg,
                @"url": urlString ?: @""
            }];

            if (completion) {
                completion(NO, errorMsg);
            }
            return;
        }

        // Promote to stage NEW slot
        BOOL promoted = [AeropushSlotManager promoteToStageNew:tempDownloadDir
                                                          hash:hash
                                                       version:state.config.appVersion];

        if (promoted) {
            [[AeropushEventHandler shared] addEvent:@"STAGE_DOWNLOAD_SUCCESS" payload:@{
                @"hash": hash ?: @""
            }];

            if (completion) {
                completion(YES, nil);
            }
        } else {
            [[AeropushEventHandler shared] addEvent:@"STAGE_DOWNLOAD_FAIL" payload:@{
                @"error": @"Failed to promote to stage slot"
            }];

            if (completion) {
                completion(NO, @"Failed to promote downloaded bundle to stage slot");
            }
        }
    }];
}

@end
