#import "AeropushMetaConstants.h"

NSString *const kAeropushMetaKeySwitchState = @"switchState";
NSString *const kAeropushMetaKeyProdSlotState = @"prodSlotState";
NSString *const kAeropushMetaKeyStageSlotState = @"stageSlotState";
NSString *const kAeropushMetaKeyProdHash = @"prodHash";
NSString *const kAeropushMetaKeyStageHash = @"stageHash";
NSString *const kAeropushMetaKeyProdLaunchCount = @"prodLaunchCount";
NSString *const kAeropushMetaKeyStageLaunchCount = @"stageLaunchCount";
NSString *const kAeropushMetaKeyRollbackTimestamp = @"rollbackTimestamp";
NSString *const kAeropushMetaKeyProdVersion = @"prodVersion";
NSString *const kAeropushMetaKeyStageVersion = @"stageVersion";

NSString *AeropushSwitchStateToString(AeropushSwitchState state) {
    switch (state) {
        case AeropushSwitchStateOff:
            return @"OFF";
        case AeropushSwitchStateProd:
            return @"PROD";
        case AeropushSwitchStateStage:
            return @"STAGE";
        default:
            return @"OFF";
    }
}

AeropushSwitchState AeropushSwitchStateFromString(NSString *string) {
    if ([string isEqualToString:@"PROD"]) {
        return AeropushSwitchStateProd;
    } else if ([string isEqualToString:@"STAGE"]) {
        return AeropushSwitchStateStage;
    }
    return AeropushSwitchStateOff;
}

NSString *AeropushSlotStateToString(AeropushSlotState state) {
    switch (state) {
        case AeropushSlotStateDefault:
            return @"DEFAULT";
        case AeropushSlotStateNew:
            return @"NEW";
        case AeropushSlotStateStable:
            return @"STABLE";
        default:
            return @"DEFAULT";
    }
}

AeropushSlotState AeropushSlotStateFromString(NSString *string) {
    if ([string isEqualToString:@"NEW"]) {
        return AeropushSlotStateNew;
    } else if ([string isEqualToString:@"STABLE"]) {
        return AeropushSlotStateStable;
    }
    return AeropushSlotStateDefault;
}
