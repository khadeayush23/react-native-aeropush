#import <Foundation/Foundation.h>

// Switch states
typedef NS_ENUM(NSInteger, AeropushSwitchState) {
    AeropushSwitchStateOff = 0,
    AeropushSwitchStateProd = 1,
    AeropushSwitchStateStage = 2,
};

// Slot states
typedef NS_ENUM(NSInteger, AeropushSlotState) {
    AeropushSlotStateDefault = 0,
    AeropushSlotStateNew = 1,
    AeropushSlotStateStable = 2,
};

// Meta dictionary keys
extern NSString *const kAeropushMetaKeySwitchState;
extern NSString *const kAeropushMetaKeyProdSlotState;
extern NSString *const kAeropushMetaKeyStageSlotState;
extern NSString *const kAeropushMetaKeyProdHash;
extern NSString *const kAeropushMetaKeyStageHash;
extern NSString *const kAeropushMetaKeyProdLaunchCount;
extern NSString *const kAeropushMetaKeyStageLaunchCount;
extern NSString *const kAeropushMetaKeyRollbackTimestamp;
extern NSString *const kAeropushMetaKeyProdVersion;
extern NSString *const kAeropushMetaKeyStageVersion;

// Conversion helpers
NSString *AeropushSwitchStateToString(AeropushSwitchState state);
AeropushSwitchState AeropushSwitchStateFromString(NSString *string);

NSString *AeropushSlotStateToString(AeropushSlotState state);
AeropushSlotState AeropushSlotStateFromString(NSString *string);
