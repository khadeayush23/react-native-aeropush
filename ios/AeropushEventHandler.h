#import <Foundation/Foundation.h>

@interface AeropushEventHandler : NSObject

+ (instancetype)shared;

/// Add an event to the cache. Events are stored as JSON strings.
- (void)addEvent:(NSString *)eventType payload:(NSDictionary *)payload;

/// Pop a batch of events (up to batch size). Returns JSON array string.
- (NSString *)popEvents;

/// Acknowledge processed events by removing them. eventIds is a JSON array of IDs.
- (void)acknowledgeEvents:(NSString *)eventIds;

/// Get count of pending events.
- (NSInteger)pendingEventCount;

/// Clear all events.
- (void)clearAllEvents;

@end
