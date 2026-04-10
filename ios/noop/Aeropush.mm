#import "Aeropush.h"

@implementation Aeropush

RCT_EXPORT_MODULE(Aeropush)

+ (NSString *)moduleName {
    return @"Aeropush";
}

- (std::shared_ptr<facebook::react::TurboModule>)getTurboModule:
    (const facebook::react::ObjCTurboModule::InitParams &)params {
    return std::make_shared<facebook::react::NativeAeropushSpecJSI>(params);
}

#pragma mark - NativeAeropushSpec No-op Methods

- (void)onLaunch:(NSString *)initParamsString {
    // No-op
}

- (void)getAeropushConfig:(RCTPromiseResolveBlock)resolve
                   reject:(RCTPromiseRejectBlock)reject {
    resolve(@"{}");
}

- (void)getAeropushMeta:(RCTPromiseResolveBlock)resolve
                 reject:(RCTPromiseRejectBlock)reject {
    resolve(@"{}");
}

- (void)sync {
    // No-op
}

- (void)downloadStageBundle:(NSString *)url
                       hash:(NSString *)hash
                    resolve:(RCTPromiseResolveBlock)resolve
                     reject:(RCTPromiseRejectBlock)reject {
    resolve(@"{\"success\":false,\"error\":\"Aeropush noop mode\"}");
}

- (void)popEvents:(RCTPromiseResolveBlock)resolve
           reject:(RCTPromiseRejectBlock)reject {
    resolve(@"[]");
}

- (void)acknowledgeEvents:(NSString *)eventIds {
    // No-op
}

- (void)toggleAeropushSwitch:(NSString *)switchState
                     resolve:(RCTPromiseResolveBlock)resolve
                      reject:(RCTPromiseRejectBlock)reject {
    resolve(@"{\"success\":false,\"error\":\"Aeropush noop mode\"}");
}

- (void)updateSdkToken:(NSString *)sdkToken
                resolve:(RCTPromiseResolveBlock)resolve
                 reject:(RCTPromiseRejectBlock)reject {
    resolve(@"{\"success\":false,\"error\":\"Aeropush noop mode\"}");
}

- (void)restart {
    // No-op
}

@end
