#import <Foundation/Foundation.h>

@interface AeropushDeviceInfo : NSObject

/// Get device metadata as a dictionary.
+ (NSDictionary *)getDeviceInfo;

/// Get device metadata as a JSON string.
+ (NSString *)getDeviceInfoJSON;

/// Get the OS version string (e.g., "17.0").
+ (NSString *)osVersion;

/// Get the device model identifier (e.g., "iPhone14,5").
+ (NSString *)deviceModel;

/// Get the device locale (e.g., "en_US").
+ (NSString *)deviceLocale;

/// Get the device timezone (e.g., "America/New_York").
+ (NSString *)deviceTimezone;

/// Check if running on a simulator.
+ (BOOL)isEmulator;

@end
