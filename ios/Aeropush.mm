#import "Aeropush.h"

#import <React/RCTBridge.h>
#import <React/RCTUtils.h>
#import <React/RCTReloadCommand.h>

#import "AeropushConstants.h"
#import "AeropushConfigConstants.h"
#import "AeropushMetaConstants.h"
#import "AeropushStateManager.h"
#import "AeropushEventHandler.h"
#import "AeropushSyncHandler.h"
#import "AeropushStageManager.h"
#import "AeropushSlotManager.h"
#import "AeropushExceptionHandler.h"
#import "AeropushDeviceInfo.h"

@interface Aeropush ()
@property (nonatomic, assign) BOOL hasListeners;
@end

@implementation Aeropush

RCT_EXPORT_MODULE(Aeropush)

+ (NSString *)moduleName {
    return @"Aeropush";
}

- (std::shared_ptr<facebook::react::TurboModule>)getTurboModule:
    (const facebook::react::ObjCTurboModule::InitParams &)params {
    return std::make_shared<facebook::react::NativeAeropushSpecJSI>(params);
}

#pragma mark - Lifecycle

- (instancetype)init {
    self = [super init];
    if (self) {
        _hasListeners = NO;

        // Listen for app becoming active
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(appDidBecomeActive)
                                                     name:UIApplicationDidBecomeActiveNotification
                                                   object:nil];
    }
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)appDidBecomeActive {
    AeropushStateManager *state = [AeropushStateManager shared];
    if (state.isInitialized && state.isMounted) {
        // Trigger sync on app resume
        [AeropushSyncHandler performSync];
    }
}

#pragma mark - NativeAeropushSpec Methods

- (void)onLaunch:(NSString *)initParamsString {
    NSLog(@"[Aeropush] onLaunch called");

    // Parse init params JSON
    NSData *data = [initParamsString dataUsingEncoding:NSUTF8StringEncoding];
    if (!data) {
        NSLog(@"[Aeropush] onLaunch: invalid params string");
        return;
    }

    NSError *error;
    NSDictionary *params = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
    if (error || !params) {
        NSLog(@"[Aeropush] onLaunch: failed to parse params: %@", error.localizedDescription);
        return;
    }

    AeropushStateManager *state = [AeropushStateManager shared];
    [state initializeWithParams:params];

    // Install exception handler
    [AeropushExceptionHandler install];

    // Mark as mounted
    state.isMounted = YES;

    // Persist config
    [state persistConfig];

    // Emit mount event
    [[AeropushEventHandler shared] addEvent:@"MOUNT" payload:@{
        @"appVersion": state.config.appVersion ?: @"",
        @"switchState": AeropushSwitchStateToString(state.meta.switchState),
    }];

    NSLog(@"[Aeropush] Initialized with uid=%@, projectId=%@, appVersion=%@",
          state.config.uid, state.config.projectId, state.config.appVersion);
}

- (void)getAeropushConfig:(RCTPromiseResolveBlock)resolve
                   reject:(RCTPromiseRejectBlock)reject {
    AeropushStateManager *state = [AeropushStateManager shared];
    NSString *configJSON = [state.config toJSONString];
    resolve(configJSON);
}

- (void)getAeropushMeta:(RCTPromiseResolveBlock)resolve
                 reject:(RCTPromiseRejectBlock)reject {
    AeropushStateManager *state = [AeropushStateManager shared];
    NSString *metaJSON = [state.meta toJSONString];
    resolve(metaJSON);
}

- (void)sync {
    NSLog(@"[Aeropush] sync called");

    AeropushStateManager *state = [AeropushStateManager shared];
    if (!state.isInitialized) {
        NSLog(@"[Aeropush] sync: not initialized, skipping");
        return;
    }

    [AeropushSyncHandler performSyncWithCompletion:^(BOOL success, NSString *error) {
        if (success) {
            NSLog(@"[Aeropush] Sync completed successfully");
        } else {
            NSLog(@"[Aeropush] Sync failed: %@", error);
        }
    }];
}

- (void)downloadStageBundle:(NSString *)url
                       hash:(NSString *)hash
                    resolve:(RCTPromiseResolveBlock)resolve
                     reject:(RCTPromiseRejectBlock)reject {
    NSLog(@"[Aeropush] downloadStageBundle: url=%@, hash=%@", url, hash);

    if (!url || url.length == 0) {
        reject(@"AEROPUSH_ERROR", @"URL is required", nil);
        return;
    }

    [AeropushStageManager downloadStageBundle:url
                                         hash:hash
                                   completion:^(BOOL success, NSString *error) {
        if (success) {
            NSDictionary *result = @{
                @"success": @YES,
                @"hash": hash ?: @""
            };
            NSData *jsonData = [NSJSONSerialization dataWithJSONObject:result options:0 error:nil];
            NSString *jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
            resolve(jsonString);
        } else {
            reject(@"AEROPUSH_ERROR", error ?: @"Download failed", nil);
        }
    }];
}

- (void)popEvents:(RCTPromiseResolveBlock)resolve
           reject:(RCTPromiseRejectBlock)reject {
    NSString *events = [[AeropushEventHandler shared] popEvents];
    resolve(events);
}

- (void)acknowledgeEvents:(NSString *)eventIds {
    [[AeropushEventHandler shared] acknowledgeEvents:eventIds];
}

- (void)toggleAeropushSwitch:(NSString *)switchState
                     resolve:(RCTPromiseResolveBlock)resolve
                      reject:(RCTPromiseRejectBlock)reject {
    NSLog(@"[Aeropush] toggleAeropushSwitch: %@", switchState);

    AeropushStateManager *state = [AeropushStateManager shared];
    AeropushSwitchState newState = AeropushSwitchStateFromString(switchState);
    AeropushSwitchState oldState = state.meta.switchState;

    state.meta.switchState = newState;
    [state persistMeta];

    [[AeropushEventHandler shared] addEvent:@"SWITCH_TOGGLED" payload:@{
        @"from": AeropushSwitchStateToString(oldState),
        @"to": AeropushSwitchStateToString(newState),
    }];

    NSDictionary *result = @{
        @"success": @YES,
        @"switchState": AeropushSwitchStateToString(newState),
        @"previousState": AeropushSwitchStateToString(oldState),
    };
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:result options:0 error:nil];
    NSString *jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    resolve(jsonString);
}

- (void)updateSdkToken:(NSString *)sdkToken
                resolve:(RCTPromiseResolveBlock)resolve
                 reject:(RCTPromiseRejectBlock)reject {
    NSLog(@"[Aeropush] updateSdkToken");

    AeropushStateManager *state = [AeropushStateManager shared];
    state.config.sdkToken = sdkToken;

    // Persist token
    [[NSUserDefaults standardUserDefaults] setObject:sdkToken
                                              forKey:[kAeropushDefaultsPrefix stringByAppendingString:@"sdk_token"]];
    [[NSUserDefaults standardUserDefaults] synchronize];
    [state persistConfig];

    [[AeropushEventHandler shared] addEvent:@"SDK_TOKEN_UPDATED" payload:@{}];

    NSDictionary *result = @{@"success": @YES};
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:result options:0 error:nil];
    NSString *jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    resolve(jsonString);
}

- (void)restart {
    NSLog(@"[Aeropush] restart called");

    [[AeropushEventHandler shared] addEvent:@"RESTART" payload:@{}];

    dispatch_async(dispatch_get_main_queue(), ^{
        RCTTriggerReloadCommandListeners(@"Aeropush restart");
    });
}

@end
