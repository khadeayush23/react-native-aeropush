#import <Foundation/Foundation.h>

typedef void (^AeropushStageCompletion)(BOOL success, NSString * _Nullable error);

@interface AeropushStageManager : NSObject

/// Download a stage bundle from the given URL.
/// @param urlString URL to download the bundle from.
/// @param hash Expected hash for validation.
/// @param completion Completion callback.
+ (void)downloadStageBundle:(NSString *)urlString
                       hash:(NSString *)hash
                 completion:(AeropushStageCompletion)completion;

@end
