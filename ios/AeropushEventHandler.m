#import "AeropushEventHandler.h"
#import "AeropushConstants.h"

@interface AeropushEventHandler ()
@property (nonatomic, strong) NSMutableArray<NSDictionary *> *events;
@property (nonatomic, strong) dispatch_queue_t eventQueue;
@end

@implementation AeropushEventHandler

+ (instancetype)shared {
    static AeropushEventHandler *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[AeropushEventHandler alloc] init];
    });
    return instance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _events = [NSMutableArray array];
        _eventQueue = dispatch_queue_create("com.aeropush.events", DISPATCH_QUEUE_SERIAL);
        [self loadPersistedEvents];
    }
    return self;
}

- (void)addEvent:(NSString *)eventType payload:(NSDictionary *)payload {
    dispatch_sync(self.eventQueue, ^{
        if (self.events.count >= kAeropushMaxEvents) {
            // Remove oldest event to make room
            [self.events removeObjectAtIndex:0];
        }

        NSString *eventId = [[NSUUID UUID] UUIDString];
        NSTimeInterval timestamp = [[NSDate date] timeIntervalSince1970] * 1000.0;

        NSMutableDictionary *event = [NSMutableDictionary dictionary];
        event[@"id"] = eventId;
        event[@"type"] = eventType ?: @"UNKNOWN";
        event[@"timestamp"] = @(timestamp);
        if (payload) {
            event[@"payload"] = payload;
        }

        [self.events addObject:[event copy]];
        [self persistEvents];
    });
}

- (NSString *)popEvents {
    __block NSString *result;
    dispatch_sync(self.eventQueue, ^{
        NSInteger batchSize = MIN(kAeropushEventBatchSize, (NSInteger)self.events.count);
        NSArray *batch = [self.events subarrayWithRange:NSMakeRange(0, batchSize)];

        NSError *error;
        NSData *jsonData = [NSJSONSerialization dataWithJSONObject:batch
                                                           options:0
                                                             error:&error];
        if (jsonData) {
            result = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
        } else {
            result = @"[]";
        }
    });
    return result;
}

- (void)acknowledgeEvents:(NSString *)eventIds {
    dispatch_sync(self.eventQueue, ^{
        NSData *data = [eventIds dataUsingEncoding:NSUTF8StringEncoding];
        if (!data) return;

        NSError *error;
        NSArray *ids = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
        if (!ids || error) return;

        NSSet *idSet = [NSSet setWithArray:ids];
        NSMutableArray *remaining = [NSMutableArray array];

        for (NSDictionary *event in self.events) {
            NSString *eventId = event[@"id"];
            if (eventId && ![idSet containsObject:eventId]) {
                [remaining addObject:event];
            }
        }

        self.events = remaining;
        [self persistEvents];
    });
}

- (NSInteger)pendingEventCount {
    __block NSInteger count;
    dispatch_sync(self.eventQueue, ^{
        count = self.events.count;
    });
    return count;
}

- (void)clearAllEvents {
    dispatch_sync(self.eventQueue, ^{
        [self.events removeAllObjects];
        [self persistEvents];
    });
}

#pragma mark - Persistence

- (void)persistEvents {
    NSError *error;
    NSData *data = [NSJSONSerialization dataWithJSONObject:self.events options:0 error:&error];
    if (data) {
        [[NSUserDefaults standardUserDefaults] setObject:data forKey:kAeropushDefaultsEvents];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
}

- (void)loadPersistedEvents {
    NSData *data = [[NSUserDefaults standardUserDefaults] objectForKey:kAeropushDefaultsEvents];
    if (data) {
        NSError *error;
        NSArray *loaded = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
        if (loaded && !error) {
            self.events = [loaded mutableCopy];
        }
    }
}

@end
