#import <Foundation/Foundation.h>
#import "AeropushMetaConstants.h"

@interface AeropushMeta : NSObject <NSCoding>

@property (nonatomic, assign) AeropushSwitchState switchState;
@property (nonatomic, assign) AeropushSlotState prodSlotState;
@property (nonatomic, assign) AeropushSlotState stageSlotState;
@property (nonatomic, copy) NSString *prodHash;
@property (nonatomic, copy) NSString *stageHash;
@property (nonatomic, assign) NSInteger prodLaunchCount;
@property (nonatomic, assign) NSInteger stageLaunchCount;
@property (nonatomic, assign) NSTimeInterval rollbackTimestamp;
@property (nonatomic, copy) NSString *prodVersion;
@property (nonatomic, copy) NSString *stageVersion;

- (instancetype)initWithDictionary:(NSDictionary *)dict;
- (NSDictionary *)toDictionary;
- (NSString *)toJSONString;

- (void)incrementProdLaunchCount;
- (void)incrementStageLaunchCount;
- (BOOL)isProdLaunchCountExceeded;
- (BOOL)isStageLaunchCountExceeded;
- (BOOL)isRollbackTTLExpired;

@end
