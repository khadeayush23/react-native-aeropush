#import <Foundation/Foundation.h>

@interface AeropushSyncHandler : NSObject

/// Perform a background sync with the Aeropush API.
/// Checks for updates, handles rollback/stabilization logic.
+ (void)performSync;

/// Perform sync and notify via callback.
+ (void)performSyncWithCompletion:(void (^)(BOOL success, NSString * _Nullable error))completion;

@end
