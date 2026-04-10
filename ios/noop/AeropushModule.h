#import <Foundation/Foundation.h>

/// No-op version of AeropushModule.
/// Always returns the default bundle URL.
@interface AeropushModule : NSObject

+ (NSURL *)getBundleURL;
+ (NSURL *)getBundleURL:(NSURL *)defaultBundleURL;

@end
