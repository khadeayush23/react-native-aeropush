#import "AeropushSyncHandler.h"
#import "AeropushStateManager.h"
#import "AeropushSlotManager.h"
#import "AeropushFileDownloader.h"
#import "AeropushDeviceInfo.h"
#import "AeropushEventHandler.h"
#import "AeropushConstants.h"
#import "AeropushMetaConstants.h"

@implementation AeropushSyncHandler

+ (void)performSync {
    [self performSyncWithCompletion:nil];
}

+ (void)performSyncWithCompletion:(void (^)(BOOL, NSString *))completion {
    AeropushStateManager *state = [AeropushStateManager shared];

    if (!state.isInitialized) {
        NSLog(@"[Aeropush] Cannot sync: not initialized");
        if (completion) {
            completion(NO, @"Not initialized");
        }
        return;
    }

    // Check rollback TTL expiration
    if ([state.meta isRollbackTTLExpired]) {
        state.meta.rollbackTimestamp = 0;
        [state persistMeta];
        NSLog(@"[Aeropush] Rollback TTL expired, cleared timestamp");
    }

    // Handle launch count exceeded -> rollback
    if (state.meta.switchState == AeropushSwitchStateProd) {
        if (state.meta.prodSlotState == AeropushSlotStateNew && [state.meta isProdLaunchCountExceeded]) {
            NSLog(@"[Aeropush] Prod launch count exceeded, falling back");
            [AeropushSlotManager fallbackProd];
        }
    } else if (state.meta.switchState == AeropushSwitchStateStage) {
        if (state.meta.stageSlotState == AeropushSlotStateNew && [state.meta isStageLaunchCountExceeded]) {
            NSLog(@"[Aeropush] Stage launch count exceeded, falling back");
            [AeropushSlotManager fallbackStage];
        }
    }

    // Build sync request body
    NSDictionary *body = [self buildSyncRequestBody];

    // Perform network request
    [self sendSyncRequest:body completion:^(NSDictionary *response, NSError *error) {
        if (error) {
            NSLog(@"[Aeropush] Sync request failed: %@", error.localizedDescription);
            if (completion) {
                completion(NO, error.localizedDescription);
            }
            return;
        }

        [self handleSyncResponse:response completion:completion];
    }];
}

+ (NSDictionary *)buildSyncRequestBody {
    AeropushStateManager *state = [AeropushStateManager shared];

    NSMutableDictionary *body = [NSMutableDictionary dictionary];
    body[@"uid"] = state.config.uid ?: @"";
    body[@"projectId"] = state.config.projectId ?: @"";
    body[@"appVersion"] = state.config.appVersion ?: @"";
    body[@"platform"] = kAeropushPlatform;
    body[@"switchState"] = AeropushSwitchStateToString(state.meta.switchState);
    body[@"prodSlotState"] = AeropushSlotStateToString(state.meta.prodSlotState);
    body[@"stageSlotState"] = AeropushSlotStateToString(state.meta.stageSlotState);
    body[@"prodHash"] = state.meta.prodHash ?: @"";
    body[@"stageHash"] = state.meta.stageHash ?: @"";
    body[@"prodVersion"] = state.meta.prodVersion ?: @"";
    body[@"stageVersion"] = state.meta.stageVersion ?: @"";
    body[@"deviceInfo"] = [AeropushDeviceInfo getDeviceInfo];

    return [body copy];
}

+ (void)sendSyncRequest:(NSDictionary *)body
             completion:(void (^)(NSDictionary *, NSError *))completion {
    AeropushStateManager *state = [AeropushStateManager shared];

    NSString *urlString = [kAeropushApiBaseUrl stringByAppendingString:kAeropushSyncEndpoint];
    NSURL *url = [NSURL URLWithString:urlString];
    if (!url) {
        NSError *error = [NSError errorWithDomain:@"com.aeropush" code:-1
                                         userInfo:@{NSLocalizedDescriptionKey: @"Invalid sync URL"}];
        completion(nil, error);
        return;
    }

    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    request.HTTPMethod = @"POST";
    [request setValue:kAeropushContentTypeJSON forHTTPHeaderField:kAeropushHeaderContentType];

    if (state.config.appToken.length > 0) {
        [request setValue:state.config.appToken forHTTPHeaderField:kAeropushHeaderAppToken];
    }
    if (state.config.sdkToken.length > 0) {
        [request setValue:[NSString stringWithFormat:@"Bearer %@", state.config.sdkToken]
       forHTTPHeaderField:kAeropushHeaderAuthorization];
    }

    NSError *jsonError;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:body options:0 error:&jsonError];
    if (jsonError) {
        completion(nil, jsonError);
        return;
    }
    request.HTTPBody = jsonData;

    NSURLSessionConfiguration *config = [NSURLSessionConfiguration defaultSessionConfiguration];
    config.timeoutIntervalForRequest = 30;
    NSURLSession *session = [NSURLSession sessionWithConfiguration:config];

    NSURLSessionDataTask *task = [session dataTaskWithRequest:request
                                           completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        if (error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                completion(nil, error);
            });
            return;
        }

        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
        if (httpResponse.statusCode < 200 || httpResponse.statusCode >= 300) {
            NSError *statusError = [NSError errorWithDomain:@"com.aeropush"
                                                       code:httpResponse.statusCode
                                                   userInfo:@{NSLocalizedDescriptionKey: [NSString stringWithFormat:@"HTTP %ld", (long)httpResponse.statusCode]}];
            dispatch_async(dispatch_get_main_queue(), ^{
                completion(nil, statusError);
            });
            return;
        }

        if (!data) {
            dispatch_async(dispatch_get_main_queue(), ^{
                completion(@{}, nil);
            });
            return;
        }

        NSError *parseError;
        NSDictionary *responseDict = [NSJSONSerialization JSONObjectWithData:data options:0 error:&parseError];
        dispatch_async(dispatch_get_main_queue(), ^{
            if (parseError) {
                completion(nil, parseError);
            } else {
                completion(responseDict, nil);
            }
        });
    }];
    [task resume];
}

+ (void)handleSyncResponse:(NSDictionary *)response
                completion:(void (^)(BOOL, NSString *))completion {
    AeropushStateManager *state = [AeropushStateManager shared];

    if (!response) {
        if (completion) {
            completion(YES, nil);
        }
        return;
    }

    // Handle rollback command from server
    NSString *command = response[@"command"];
    if ([command isEqualToString:@"ROLLBACK_PROD"]) {
        [AeropushSlotManager rollbackProd];
    } else if ([command isEqualToString:@"ROLLBACK_STAGE"]) {
        [AeropushSlotManager rollbackStage];
    }

    // Handle stabilize command
    if ([command isEqualToString:@"STABILIZE_PROD"]) {
        [AeropushSlotManager stabilizeProd];
    } else if ([command isEqualToString:@"STABILIZE_STAGE"]) {
        [AeropushSlotManager stabilizeStage];
    }

    // Handle new bundle available
    NSDictionary *update = response[@"update"];
    if (update) {
        NSString *downloadUrl = update[@"url"];
        NSString *hash = update[@"hash"];
        NSString *version = update[@"version"];
        NSString *target = update[@"target"]; // "prod" or "stage"

        if (downloadUrl.length > 0 && hash.length > 0) {
            NSLog(@"[Aeropush] New bundle available for %@: %@", target, hash);

            NSString *destDir;
            if ([target isEqualToString:@"stage"]) {
                destDir = [[state stageDirectoryPath] stringByAppendingPathComponent:@"_download_temp"];
            } else {
                destDir = [[state prodDirectoryPath] stringByAppendingPathComponent:@"_download_temp"];
            }

            [AeropushFileDownloader downloadAndUnzipFromURL:downloadUrl
                                                toDirectory:destDir
                                               expectedHash:hash
                                                 completion:^(NSString *filePath, NSError *downloadError) {
                if (downloadError) {
                    NSLog(@"[Aeropush] Bundle download failed: %@", downloadError.localizedDescription);
                    [[AeropushEventHandler shared] addEvent:@"SYNC_DOWNLOAD_FAIL" payload:@{
                        @"error": downloadError.localizedDescription,
                        @"target": target ?: @"prod"
                    }];
                } else {
                    if ([target isEqualToString:@"stage"]) {
                        [AeropushSlotManager promoteToStageNew:destDir hash:hash version:version];
                    } else {
                        [AeropushSlotManager promoteToProdNew:destDir hash:hash version:version];
                    }
                }
            }];
        }
    }

    // Handle SDK token update
    NSString *newSdkToken = response[@"sdkToken"];
    if (newSdkToken.length > 0) {
        state.config.sdkToken = newSdkToken;
        [[NSUserDefaults standardUserDefaults] setObject:newSdkToken
                                                  forKey:[kAeropushDefaultsPrefix stringByAppendingString:@"sdk_token"]];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }

    [[AeropushEventHandler shared] addEvent:@"SYNC_COMPLETE" payload:@{
        @"hasUpdate": @(update != nil),
        @"command": command ?: @""
    }];

    if (completion) {
        completion(YES, nil);
    }
}

@end
