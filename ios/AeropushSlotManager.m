#import "AeropushSlotManager.h"
#import "AeropushStateManager.h"
#import "AeropushFileManager.h"
#import "AeropushEventHandler.h"
#import "AeropushConstants.h"

@implementation AeropushSlotManager

+ (void)rollbackProd {
    AeropushStateManager *state = [AeropushStateManager shared];
    NSString *prodDir = [state prodDirectoryPath];

    // Clear NEW and STABLE directories
    NSString *newDir = [prodDir stringByAppendingPathComponent:kAeropushNewDir];
    NSString *stableDir = [prodDir stringByAppendingPathComponent:kAeropushStableDir];

    [AeropushFileManager clearDirectoryAtPath:newDir];
    [AeropushFileManager clearDirectoryAtPath:stableDir];

    // Reset meta
    state.meta.prodSlotState = AeropushSlotStateDefault;
    state.meta.prodHash = @"";
    state.meta.prodLaunchCount = 0;
    state.meta.prodVersion = @"";
    state.meta.rollbackTimestamp = [[NSDate date] timeIntervalSince1970];
    [state persistMeta];

    // Emit event
    [[AeropushEventHandler shared] addEvent:@"ROLLBACK_PROD" payload:@{
        @"reason": @"manual_or_exceeded_launch_count"
    }];

    NSLog(@"[Aeropush] Rolled back prod slot to DEFAULT");
}

+ (void)rollbackStage {
    AeropushStateManager *state = [AeropushStateManager shared];
    NSString *stageDir = [state stageDirectoryPath];

    NSString *newDir = [stageDir stringByAppendingPathComponent:kAeropushNewDir];
    NSString *stableDir = [stageDir stringByAppendingPathComponent:kAeropushStableDir];

    [AeropushFileManager clearDirectoryAtPath:newDir];
    [AeropushFileManager clearDirectoryAtPath:stableDir];

    state.meta.stageSlotState = AeropushSlotStateDefault;
    state.meta.stageHash = @"";
    state.meta.stageLaunchCount = 0;
    state.meta.stageVersion = @"";
    [state persistMeta];

    [[AeropushEventHandler shared] addEvent:@"ROLLBACK_STAGE" payload:@{
        @"reason": @"manual_or_exceeded_launch_count"
    }];

    NSLog(@"[Aeropush] Rolled back stage slot to DEFAULT");
}

+ (void)fallbackProd {
    AeropushStateManager *state = [AeropushStateManager shared];
    NSString *prodDir = [state prodDirectoryPath];
    NSString *stableDir = [prodDir stringByAppendingPathComponent:kAeropushStableDir];
    NSString *stableBundlePath = [stableDir stringByAppendingPathComponent:kAeropushBundleFilename];

    // Clear NEW slot
    NSString *newDir = [prodDir stringByAppendingPathComponent:kAeropushNewDir];
    [AeropushFileManager clearDirectoryAtPath:newDir];

    // Check if STABLE exists
    if ([AeropushFileManager fileExistsAtPath:stableBundlePath]) {
        state.meta.prodSlotState = AeropushSlotStateStable;
        state.meta.prodLaunchCount = 0;
        NSLog(@"[Aeropush] Prod fell back to STABLE slot");
    } else {
        state.meta.prodSlotState = AeropushSlotStateDefault;
        state.meta.prodHash = @"";
        state.meta.prodVersion = @"";
        NSLog(@"[Aeropush] Prod fell back to DEFAULT (no STABLE available)");
    }

    [state persistMeta];

    [[AeropushEventHandler shared] addEvent:@"FALLBACK_PROD" payload:@{
        @"newState": AeropushSlotStateToString(state.meta.prodSlotState)
    }];
}

+ (void)fallbackStage {
    AeropushStateManager *state = [AeropushStateManager shared];
    NSString *stageDir = [state stageDirectoryPath];
    NSString *stableDir = [stageDir stringByAppendingPathComponent:kAeropushStableDir];
    NSString *stableBundlePath = [stableDir stringByAppendingPathComponent:kAeropushBundleFilename];

    NSString *newDir = [stageDir stringByAppendingPathComponent:kAeropushNewDir];
    [AeropushFileManager clearDirectoryAtPath:newDir];

    if ([AeropushFileManager fileExistsAtPath:stableBundlePath]) {
        state.meta.stageSlotState = AeropushSlotStateStable;
        state.meta.stageLaunchCount = 0;
        NSLog(@"[Aeropush] Stage fell back to STABLE slot");
    } else {
        state.meta.stageSlotState = AeropushSlotStateDefault;
        state.meta.stageHash = @"";
        state.meta.stageVersion = @"";
        NSLog(@"[Aeropush] Stage fell back to DEFAULT (no STABLE available)");
    }

    [state persistMeta];

    [[AeropushEventHandler shared] addEvent:@"FALLBACK_STAGE" payload:@{
        @"newState": AeropushSlotStateToString(state.meta.stageSlotState)
    }];
}

+ (void)stabilizeProd {
    AeropushStateManager *state = [AeropushStateManager shared];
    NSString *prodDir = [state prodDirectoryPath];
    NSString *newDir = [prodDir stringByAppendingPathComponent:kAeropushNewDir];
    NSString *stableDir = [prodDir stringByAppendingPathComponent:kAeropushStableDir];

    // Clear old stable
    [AeropushFileManager clearDirectoryAtPath:stableDir];

    // Move NEW -> STABLE
    if ([AeropushFileManager copyDirectoryFromPath:newDir toPath:stableDir]) {
        [AeropushFileManager clearDirectoryAtPath:newDir];

        state.meta.prodSlotState = AeropushSlotStateStable;
        state.meta.prodLaunchCount = 0;
        [state persistMeta];

        [[AeropushEventHandler shared] addEvent:@"STABILIZE_PROD" payload:@{
            @"hash": state.meta.prodHash ?: @""
        }];

        NSLog(@"[Aeropush] Prod bundle stabilized (NEW -> STABLE)");
    } else {
        NSLog(@"[Aeropush] Failed to stabilize prod bundle");
    }
}

+ (void)stabilizeStage {
    AeropushStateManager *state = [AeropushStateManager shared];
    NSString *stageDir = [state stageDirectoryPath];
    NSString *newDir = [stageDir stringByAppendingPathComponent:kAeropushNewDir];
    NSString *stableDir = [stageDir stringByAppendingPathComponent:kAeropushStableDir];

    [AeropushFileManager clearDirectoryAtPath:stableDir];

    if ([AeropushFileManager copyDirectoryFromPath:newDir toPath:stableDir]) {
        [AeropushFileManager clearDirectoryAtPath:newDir];

        state.meta.stageSlotState = AeropushSlotStateStable;
        state.meta.stageLaunchCount = 0;
        [state persistMeta];

        [[AeropushEventHandler shared] addEvent:@"STABILIZE_STAGE" payload:@{
            @"hash": state.meta.stageHash ?: @""
        }];

        NSLog(@"[Aeropush] Stage bundle stabilized (NEW -> STABLE)");
    } else {
        NSLog(@"[Aeropush] Failed to stabilize stage bundle");
    }
}

+ (BOOL)promoteToProdNew:(NSString *)sourcePath hash:(NSString *)hash version:(NSString *)version {
    AeropushStateManager *state = [AeropushStateManager shared];
    NSString *prodDir = [state prodDirectoryPath];
    NSString *newDir = [prodDir stringByAppendingPathComponent:kAeropushNewDir];

    // Clear existing NEW
    [AeropushFileManager clearDirectoryAtPath:newDir];
    [AeropushFileManager createDirectoryAtPath:newDir];

    // Move downloaded content to NEW
    if ([AeropushFileManager moveFromPath:sourcePath toPath:newDir]) {
        state.meta.prodSlotState = AeropushSlotStateNew;
        state.meta.prodHash = hash ?: @"";
        state.meta.prodLaunchCount = 0;
        state.meta.prodVersion = version ?: @"";
        [state persistMeta];

        [[AeropushEventHandler shared] addEvent:@"PROMOTE_PROD_NEW" payload:@{
            @"hash": hash ?: @"",
            @"version": version ?: @""
        }];

        NSLog(@"[Aeropush] Promoted bundle to prod NEW slot with hash: %@", hash);
        return YES;
    }

    NSLog(@"[Aeropush] Failed to promote bundle to prod NEW slot");
    return NO;
}

+ (BOOL)promoteToStageNew:(NSString *)sourcePath hash:(NSString *)hash version:(NSString *)version {
    AeropushStateManager *state = [AeropushStateManager shared];
    NSString *stageDir = [state stageDirectoryPath];
    NSString *newDir = [stageDir stringByAppendingPathComponent:kAeropushNewDir];

    [AeropushFileManager clearDirectoryAtPath:newDir];
    [AeropushFileManager createDirectoryAtPath:newDir];

    if ([AeropushFileManager moveFromPath:sourcePath toPath:newDir]) {
        state.meta.stageSlotState = AeropushSlotStateNew;
        state.meta.stageHash = hash ?: @"";
        state.meta.stageLaunchCount = 0;
        state.meta.stageVersion = version ?: @"";
        [state persistMeta];

        [[AeropushEventHandler shared] addEvent:@"PROMOTE_STAGE_NEW" payload:@{
            @"hash": hash ?: @"",
            @"version": version ?: @""
        }];

        NSLog(@"[Aeropush] Promoted bundle to stage NEW slot with hash: %@", hash);
        return YES;
    }

    NSLog(@"[Aeropush] Failed to promote bundle to stage NEW slot");
    return NO;
}

@end
