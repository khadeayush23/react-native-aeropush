#import <Foundation/Foundation.h>

/// Static utility class for resolving the correct bundle URL at app launch.
/// Use in your AppDelegate to get the bundle URL:
///
///   NSURL *bundleURL = [AeropushModule getBundleURL:defaultBundleURL];
///
@interface AeropushModule : NSObject

/// Get the Aeropush bundle URL, returning the default RN bundle if no Aeropush bundle is active.
+ (NSURL *)getBundleURL;

/// Get the Aeropush bundle URL with a fallback default URL.
/// @param defaultBundleURL The default React Native bundle URL from the app.
/// @return The appropriate bundle URL (Aeropush override or default).
+ (NSURL *)getBundleURL:(NSURL *)defaultBundleURL;

@end
