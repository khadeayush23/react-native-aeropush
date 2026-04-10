#import "AeropushStateManager.h"
#import "AeropushConstants.h"
#import "AeropushConfigConstants.h"
#import "AeropushMetaConstants.h"

@implementation AeropushStateManager

+ (instancetype)shared {
    static AeropushStateManager *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[AeropushStateManager alloc] init];
    });
    return instance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _config = [[AeropushConfig alloc] init];
        _meta = [[AeropushMeta alloc] init];
        _isMounted = NO;
        _isInitialized = NO;
    }
    return self;
}

- (void)initializeWithParams:(NSDictionary *)params {
    self.config = [[AeropushConfig alloc] initWithDictionary:params];

    // Set up files directory if not provided
    if (self.config.filesDirectory.length == 0) {
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *documentsDir = paths.firstObject;
        self.config.filesDirectory = documentsDir;
    }

    // Ensure directories exist
    [self ensureDirectoriesExist];

    // Load persisted meta
    [self loadPersistedState];

    // Load persisted SDK token if not provided
    if (self.config.sdkToken.length == 0) {
        NSString *persistedToken = [[NSUserDefaults standardUserDefaults] stringForKey:[kAeropushDefaultsPrefix stringByAppendingString:@"sdk_token"]];
        if (persistedToken.length > 0) {
            self.config.sdkToken = persistedToken;
        }
    }

    self.isInitialized = YES;
}

- (void)ensureDirectoriesExist {
    NSFileManager *fm = [NSFileManager defaultManager];
    NSError *error;

    NSArray *dirs = @[
        [self prodDirectoryPath],
        [self stageDirectoryPath],
        [[self prodDirectoryPath] stringByAppendingPathComponent:kAeropushNewDir],
        [[self prodDirectoryPath] stringByAppendingPathComponent:kAeropushStableDir],
        [[self stageDirectoryPath] stringByAppendingPathComponent:kAeropushNewDir],
        [[self stageDirectoryPath] stringByAppendingPathComponent:kAeropushStableDir],
    ];

    for (NSString *dir in dirs) {
        if (![fm fileExistsAtPath:dir]) {
            [fm createDirectoryAtPath:dir
          withIntermediateDirectories:YES
                           attributes:nil
                                error:&error];
            if (error) {
                NSLog(@"[Aeropush] Error creating directory %@: %@", dir, error.localizedDescription);
                error = nil;
            }
        }
    }
}

- (void)persistConfig {
    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:self.config requiringSecureCoding:NO error:nil];
    [[NSUserDefaults standardUserDefaults] setObject:data forKey:kAeropushDefaultsConfig];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)persistMeta {
    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:self.meta requiringSecureCoding:NO error:nil];
    [[NSUserDefaults standardUserDefaults] setObject:data forKey:kAeropushDefaultsMeta];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)loadPersistedState {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

    // Load meta
    NSData *metaData = [defaults objectForKey:kAeropushDefaultsMeta];
    if (metaData) {
        @try {
            AeropushMeta *persistedMeta = [NSKeyedUnarchiver unarchivedObjectOfClass:[AeropushMeta class]
                                                                            fromData:metaData
                                                                               error:nil];
            if (persistedMeta) {
                self.meta = persistedMeta;
            }
        } @catch (NSException *exception) {
            NSLog(@"[Aeropush] Error loading persisted meta: %@", exception.reason);
            self.meta = [[AeropushMeta alloc] init];
        }
    }
}

- (void)resetMeta {
    self.meta = [[AeropushMeta alloc] init];
    [self persistMeta];
}

#pragma mark - Path Helpers

- (NSString *)prodDirectoryPath {
    return [self.config.filesDirectory stringByAppendingPathComponent:kAeropushProdDir];
}

- (NSString *)stageDirectoryPath {
    return [self.config.filesDirectory stringByAppendingPathComponent:kAeropushStageDir];
}

- (NSString *)newSlotPath {
    return kAeropushNewDir;
}

- (NSString *)stableSlotPath {
    return kAeropushStableDir;
}

- (NSString *)prodBundlePath {
    NSString *baseDir = [self prodDirectoryPath];
    NSString *slotDir;

    switch (self.meta.prodSlotState) {
        case AeropushSlotStateNew:
            slotDir = kAeropushNewDir;
            break;
        case AeropushSlotStateStable:
            slotDir = kAeropushStableDir;
            break;
        case AeropushSlotStateDefault:
        default:
            return nil;
    }

    return [[baseDir stringByAppendingPathComponent:slotDir]
            stringByAppendingPathComponent:kAeropushBundleFilename];
}

- (NSString *)stageBundlePath {
    NSString *baseDir = [self stageDirectoryPath];
    NSString *slotDir;

    switch (self.meta.stageSlotState) {
        case AeropushSlotStateNew:
            slotDir = kAeropushNewDir;
            break;
        case AeropushSlotStateStable:
            slotDir = kAeropushStableDir;
            break;
        case AeropushSlotStateDefault:
        default:
            return nil;
    }

    return [[baseDir stringByAppendingPathComponent:slotDir]
            stringByAppendingPathComponent:kAeropushBundleFilename];
}

@end
