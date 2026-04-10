#import "AeropushMeta.h"
#import "AeropushConstants.h"

@implementation AeropushMeta

- (instancetype)init {
    self = [super init];
    if (self) {
        _switchState = AeropushSwitchStateOff;
        _prodSlotState = AeropushSlotStateDefault;
        _stageSlotState = AeropushSlotStateDefault;
        _prodHash = @"";
        _stageHash = @"";
        _prodLaunchCount = 0;
        _stageLaunchCount = 0;
        _rollbackTimestamp = 0;
        _prodVersion = @"";
        _stageVersion = @"";
    }
    return self;
}

- (instancetype)initWithDictionary:(NSDictionary *)dict {
    self = [super init];
    if (self) {
        _switchState = AeropushSwitchStateFromString(dict[kAeropushMetaKeySwitchState] ?: @"OFF");
        _prodSlotState = AeropushSlotStateFromString(dict[kAeropushMetaKeyProdSlotState] ?: @"DEFAULT");
        _stageSlotState = AeropushSlotStateFromString(dict[kAeropushMetaKeyStageSlotState] ?: @"DEFAULT");
        _prodHash = dict[kAeropushMetaKeyProdHash] ?: @"";
        _stageHash = dict[kAeropushMetaKeyStageHash] ?: @"";
        _prodLaunchCount = [dict[kAeropushMetaKeyProdLaunchCount] integerValue];
        _stageLaunchCount = [dict[kAeropushMetaKeyStageLaunchCount] integerValue];
        _rollbackTimestamp = [dict[kAeropushMetaKeyRollbackTimestamp] doubleValue];
        _prodVersion = dict[kAeropushMetaKeyProdVersion] ?: @"";
        _stageVersion = dict[kAeropushMetaKeyStageVersion] ?: @"";
    }
    return self;
}

- (NSDictionary *)toDictionary {
    return @{
        kAeropushMetaKeySwitchState: AeropushSwitchStateToString(self.switchState),
        kAeropushMetaKeyProdSlotState: AeropushSlotStateToString(self.prodSlotState),
        kAeropushMetaKeyStageSlotState: AeropushSlotStateToString(self.stageSlotState),
        kAeropushMetaKeyProdHash: self.prodHash ?: @"",
        kAeropushMetaKeyStageHash: self.stageHash ?: @"",
        kAeropushMetaKeyProdLaunchCount: @(self.prodLaunchCount),
        kAeropushMetaKeyStageLaunchCount: @(self.stageLaunchCount),
        kAeropushMetaKeyRollbackTimestamp: @(self.rollbackTimestamp),
        kAeropushMetaKeyProdVersion: self.prodVersion ?: @"",
        kAeropushMetaKeyStageVersion: self.stageVersion ?: @"",
    };
}

- (NSString *)toJSONString {
    NSError *error;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:[self toDictionary]
                                                       options:0
                                                         error:&error];
    if (!jsonData) {
        return @"{}";
    }
    return [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
}

- (void)incrementProdLaunchCount {
    self.prodLaunchCount += 1;
}

- (void)incrementStageLaunchCount {
    self.stageLaunchCount += 1;
}

- (BOOL)isProdLaunchCountExceeded {
    return self.prodLaunchCount >= kAeropushMaxLaunchCount;
}

- (BOOL)isStageLaunchCountExceeded {
    return self.stageLaunchCount >= kAeropushMaxLaunchCount;
}

- (BOOL)isRollbackTTLExpired {
    if (self.rollbackTimestamp <= 0) {
        return NO;
    }
    NSTimeInterval now = [[NSDate date] timeIntervalSince1970];
    return (now - self.rollbackTimestamp) >= kAeropushRollbackTTL;
}

#pragma mark - NSCoding

- (void)encodeWithCoder:(NSCoder *)coder {
    [coder encodeInteger:self.switchState forKey:kAeropushMetaKeySwitchState];
    [coder encodeInteger:self.prodSlotState forKey:kAeropushMetaKeyProdSlotState];
    [coder encodeInteger:self.stageSlotState forKey:kAeropushMetaKeyStageSlotState];
    [coder encodeObject:self.prodHash forKey:kAeropushMetaKeyProdHash];
    [coder encodeObject:self.stageHash forKey:kAeropushMetaKeyStageHash];
    [coder encodeInteger:self.prodLaunchCount forKey:kAeropushMetaKeyProdLaunchCount];
    [coder encodeInteger:self.stageLaunchCount forKey:kAeropushMetaKeyStageLaunchCount];
    [coder encodeDouble:self.rollbackTimestamp forKey:kAeropushMetaKeyRollbackTimestamp];
    [coder encodeObject:self.prodVersion forKey:kAeropushMetaKeyProdVersion];
    [coder encodeObject:self.stageVersion forKey:kAeropushMetaKeyStageVersion];
}

- (instancetype)initWithCoder:(NSCoder *)coder {
    self = [super init];
    if (self) {
        _switchState = (AeropushSwitchState)[coder decodeIntegerForKey:kAeropushMetaKeySwitchState];
        _prodSlotState = (AeropushSlotState)[coder decodeIntegerForKey:kAeropushMetaKeyProdSlotState];
        _stageSlotState = (AeropushSlotState)[coder decodeIntegerForKey:kAeropushMetaKeyStageSlotState];
        _prodHash = [coder decodeObjectForKey:kAeropushMetaKeyProdHash] ?: @"";
        _stageHash = [coder decodeObjectForKey:kAeropushMetaKeyStageHash] ?: @"";
        _prodLaunchCount = [coder decodeIntegerForKey:kAeropushMetaKeyProdLaunchCount];
        _stageLaunchCount = [coder decodeIntegerForKey:kAeropushMetaKeyStageLaunchCount];
        _rollbackTimestamp = [coder decodeDoubleForKey:kAeropushMetaKeyRollbackTimestamp];
        _prodVersion = [coder decodeObjectForKey:kAeropushMetaKeyProdVersion] ?: @"";
        _stageVersion = [coder decodeObjectForKey:kAeropushMetaKeyStageVersion] ?: @"";
    }
    return self;
}

@end
