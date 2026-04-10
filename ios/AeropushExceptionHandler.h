#import <Foundation/Foundation.h>

@interface AeropushExceptionHandler : NSObject

/// Install the exception and signal handlers.
+ (void)install;

/// Uninstall the exception and signal handlers.
+ (void)uninstall;

/// Set a crash marker indicating an Aeropush bundle was active.
+ (void)setCrashMarker;

/// Clear the crash marker.
+ (void)clearCrashMarker;

/// Check if there is a crash marker from a previous session.
+ (BOOL)hasCrashMarker;

/// Handle post-crash rollback if needed.
/// Call this at app startup before loading any Aeropush bundle.
+ (void)handlePostCrashRollbackIfNeeded;

@end
