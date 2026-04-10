#import <Foundation/Foundation.h>
#import "AeropushConfig.h"
#import "AeropushMeta.h"

@interface AeropushStateManager : NSObject

@property (nonatomic, strong) AeropushConfig *config;
@property (nonatomic, strong) AeropushMeta *meta;
@property (nonatomic, assign) BOOL isMounted;
@property (nonatomic, assign) BOOL isInitialized;

+ (instancetype)shared;

- (void)initializeWithParams:(NSDictionary *)params;
- (void)persistConfig;
- (void)persistMeta;
- (void)loadPersistedState;
- (void)resetMeta;

- (NSString *)prodBundlePath;
- (NSString *)stageBundlePath;
- (NSString *)newSlotPath;
- (NSString *)stableSlotPath;
- (NSString *)prodDirectoryPath;
- (NSString *)stageDirectoryPath;

@end
