#import "AeropushDeviceInfo.h"
#import <UIKit/UIKit.h>
#import <sys/utsname.h>

@implementation AeropushDeviceInfo

+ (NSDictionary *)getDeviceInfo {
    return @{
        @"platform": @"ios",
        @"osVersion": [self osVersion],
        @"deviceModel": [self deviceModel],
        @"locale": [self deviceLocale],
        @"timezone": [self deviceTimezone],
        @"isEmulator": @([self isEmulator]),
        @"appBundleId": [[NSBundle mainBundle] bundleIdentifier] ?: @"",
        @"appBuildNumber": [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleVersion"] ?: @"",
    };
}

+ (NSString *)getDeviceInfoJSON {
    NSError *error;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:[self getDeviceInfo]
                                                       options:0
                                                         error:&error];
    if (!jsonData) {
        return @"{}";
    }
    return [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
}

+ (NSString *)osVersion {
    return [[UIDevice currentDevice] systemVersion];
}

+ (NSString *)deviceModel {
    struct utsname systemInfo;
    uname(&systemInfo);
    return [NSString stringWithCString:systemInfo.machine encoding:NSUTF8StringEncoding];
}

+ (NSString *)deviceLocale {
    return [[NSLocale currentLocale] localeIdentifier];
}

+ (NSString *)deviceTimezone {
    return [[NSTimeZone localTimeZone] name];
}

+ (BOOL)isEmulator {
#if TARGET_IPHONE_SIMULATOR
    return YES;
#else
    return NO;
#endif
}

@end
