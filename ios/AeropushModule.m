#import "AeropushModule.h"
#import "AeropushStateManager.h"
#import "AeropushExceptionHandler.h"
#import "AeropushConstants.h"
#import "AeropushMetaConstants.h"
#import "AeropushFileManager.h"

@implementation AeropushModule

+ (NSURL *)getBundleURL {
    // Default: main bundle's main.jsbundle
    NSURL *defaultURL = [[NSBundle mainBundle] URLForResource:@"main" withExtension:@"jsbundle"];
    return [self getBundleURL:defaultURL];
}

+ (NSURL *)getBundleURL:(NSURL *)defaultBundleURL {
    // Handle post-crash rollback before attempting to load an Aeropush bundle
    [AeropushExceptionHandler handlePostCrashRollbackIfNeeded];

    AeropushStateManager *state = [AeropushStateManager shared];

    // Load persisted state if not yet initialized
    if (!state.isInitialized) {
        [state loadPersistedState];
    }

    AeropushMeta *meta = state.meta;

    // Determine which bundle to load based on switch state
    switch (meta.switchState) {
        case AeropushSwitchStateProd: {
            NSURL *prodURL = [self resolveProdBundleURL:defaultBundleURL];
            if (prodURL) {
                NSLog(@"[Aeropush] Loading PROD bundle: %@", prodURL.path);
                [AeropushExceptionHandler setCrashMarker];
                return prodURL;
            }
            NSLog(@"[Aeropush] PROD bundle not available, using default");
            return defaultBundleURL;
        }
        case AeropushSwitchStateStage: {
            NSURL *stageURL = [self resolveStageBundleURL:defaultBundleURL];
            if (stageURL) {
                NSLog(@"[Aeropush] Loading STAGE bundle: %@", stageURL.path);
                [AeropushExceptionHandler setCrashMarker];
                return stageURL;
            }
            NSLog(@"[Aeropush] STAGE bundle not available, using default");
            return defaultBundleURL;
        }
        case AeropushSwitchStateOff:
        default:
            NSLog(@"[Aeropush] Switch OFF, using default bundle");
            return defaultBundleURL;
    }
}

#pragma mark - Private

+ (NSURL *)resolveProdBundleURL:(NSURL *)defaultBundleURL {
    AeropushStateManager *state = [AeropushStateManager shared];
    AeropushMeta *meta = state.meta;

    switch (meta.prodSlotState) {
        case AeropushSlotStateNew: {
            NSString *bundlePath = [self prodNewBundlePath];
            if ([self isValidBundlePath:bundlePath version:meta.prodVersion]) {
                [meta incrementProdLaunchCount];
                [state persistMeta];
                return [NSURL fileURLWithPath:bundlePath];
            }
            // Corruption detected: fallback
            NSLog(@"[Aeropush] PROD NEW bundle corrupted/missing, falling back");
            return [self handleProdCorruption:defaultBundleURL];
        }
        case AeropushSlotStateStable: {
            NSString *bundlePath = [self prodStableBundlePath];
            if ([self isValidBundlePath:bundlePath version:meta.prodVersion]) {
                return [NSURL fileURLWithPath:bundlePath];
            }
            NSLog(@"[Aeropush] PROD STABLE bundle corrupted/missing, falling back to default");
            // Reset to DEFAULT
            meta.prodSlotState = AeropushSlotStateDefault;
            meta.prodHash = @"";
            meta.prodVersion = @"";
            [state persistMeta];
            return defaultBundleURL;
        }
        case AeropushSlotStateDefault:
        default:
            return defaultBundleURL;
    }
}

+ (NSURL *)resolveStageBundleURL:(NSURL *)defaultBundleURL {
    AeropushStateManager *state = [AeropushStateManager shared];
    AeropushMeta *meta = state.meta;

    switch (meta.stageSlotState) {
        case AeropushSlotStateNew: {
            NSString *bundlePath = [self stageNewBundlePath];
            if ([self isValidBundlePath:bundlePath version:meta.stageVersion]) {
                [meta incrementStageLaunchCount];
                [state persistMeta];
                return [NSURL fileURLWithPath:bundlePath];
            }
            NSLog(@"[Aeropush] STAGE NEW bundle corrupted/missing, falling back");
            return [self handleStageCorruption:defaultBundleURL];
        }
        case AeropushSlotStateStable: {
            NSString *bundlePath = [self stageStableBundlePath];
            if ([self isValidBundlePath:bundlePath version:meta.stageVersion]) {
                return [NSURL fileURLWithPath:bundlePath];
            }
            NSLog(@"[Aeropush] STAGE STABLE bundle corrupted/missing, falling back to default");
            meta.stageSlotState = AeropushSlotStateDefault;
            meta.stageHash = @"";
            meta.stageVersion = @"";
            [state persistMeta];
            return defaultBundleURL;
        }
        case AeropushSlotStateDefault:
        default:
            return defaultBundleURL;
    }
}

+ (NSURL *)handleProdCorruption:(NSURL *)defaultBundleURL {
    AeropushStateManager *state = [AeropushStateManager shared];
    AeropushMeta *meta = state.meta;

    // Try STABLE fallback
    NSString *stablePath = [self prodStableBundlePath];
    if ([self isValidBundlePath:stablePath version:meta.prodVersion]) {
        // Clear NEW, use STABLE
        NSString *newDir = [[state prodDirectoryPath] stringByAppendingPathComponent:kAeropushNewDir];
        [AeropushFileManager clearDirectoryAtPath:newDir];
        meta.prodSlotState = AeropushSlotStateStable;
        meta.prodLaunchCount = 0;
        [state persistMeta];
        return [NSURL fileURLWithPath:stablePath];
    }

    // No STABLE either, reset to DEFAULT
    meta.prodSlotState = AeropushSlotStateDefault;
    meta.prodHash = @"";
    meta.prodLaunchCount = 0;
    meta.prodVersion = @"";
    [state persistMeta];
    return defaultBundleURL;
}

+ (NSURL *)handleStageCorruption:(NSURL *)defaultBundleURL {
    AeropushStateManager *state = [AeropushStateManager shared];
    AeropushMeta *meta = state.meta;

    NSString *stablePath = [self stageStableBundlePath];
    if ([self isValidBundlePath:stablePath version:meta.stageVersion]) {
        NSString *newDir = [[state stageDirectoryPath] stringByAppendingPathComponent:kAeropushNewDir];
        [AeropushFileManager clearDirectoryAtPath:newDir];
        meta.stageSlotState = AeropushSlotStateStable;
        meta.stageLaunchCount = 0;
        [state persistMeta];
        return [NSURL fileURLWithPath:stablePath];
    }

    meta.stageSlotState = AeropushSlotStateDefault;
    meta.stageHash = @"";
    meta.stageLaunchCount = 0;
    meta.stageVersion = @"";
    [state persistMeta];
    return defaultBundleURL;
}

+ (BOOL)isValidBundlePath:(NSString *)path version:(NSString *)version {
    if (!path || path.length == 0) {
        return NO;
    }

    // Check file exists
    if (![AeropushFileManager fileExistsAtPath:path]) {
        return NO;
    }

    // Check file size > 0
    if ([AeropushFileManager fileSizeAtPath:path] == 0) {
        return NO;
    }

    // Version validation: if we have a stored version, check it matches the app version
    // (prevents loading bundles from a different app version)
    AeropushStateManager *state = [AeropushStateManager shared];
    if (version.length > 0 && state.config.appVersion.length > 0) {
        if (![version isEqualToString:state.config.appVersion]) {
            NSLog(@"[Aeropush] Bundle version mismatch: bundle=%@, app=%@", version, state.config.appVersion);
            return NO;
        }
    }

    return YES;
}

#pragma mark - Path Helpers

+ (NSString *)prodNewBundlePath {
    AeropushStateManager *state = [AeropushStateManager shared];
    return [[[state prodDirectoryPath]
             stringByAppendingPathComponent:kAeropushNewDir]
            stringByAppendingPathComponent:kAeropushBundleFilename];
}

+ (NSString *)prodStableBundlePath {
    AeropushStateManager *state = [AeropushStateManager shared];
    return [[[state prodDirectoryPath]
             stringByAppendingPathComponent:kAeropushStableDir]
            stringByAppendingPathComponent:kAeropushBundleFilename];
}

+ (NSString *)stageNewBundlePath {
    AeropushStateManager *state = [AeropushStateManager shared];
    return [[[state stageDirectoryPath]
             stringByAppendingPathComponent:kAeropushNewDir]
            stringByAppendingPathComponent:kAeropushBundleFilename];
}

+ (NSString *)stageStableBundlePath {
    AeropushStateManager *state = [AeropushStateManager shared];
    return [[[state stageDirectoryPath]
             stringByAppendingPathComponent:kAeropushStableDir]
            stringByAppendingPathComponent:kAeropushBundleFilename];
}

@end
