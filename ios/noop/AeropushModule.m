#import "AeropushModule.h"

@implementation AeropushModule

+ (NSURL *)getBundleURL {
    return [[NSBundle mainBundle] URLForResource:@"main" withExtension:@"jsbundle"];
}

+ (NSURL *)getBundleURL:(NSURL *)defaultBundleURL {
    return defaultBundleURL;
}

@end
