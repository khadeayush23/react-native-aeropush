#import "AeropushConfig.h"
#import "AeropushConfigConstants.h"
#import "AeropushConstants.h"

@implementation AeropushConfig

- (instancetype)init {
    self = [super init];
    if (self) {
        _uid = @"";
        _projectId = @"";
        _appToken = @"";
        _sdkToken = @"";
        _appVersion = @"";
        _filesDirectory = @"";
        _publicSigningKey = @"";
    }
    return self;
}

- (instancetype)initWithDictionary:(NSDictionary *)dict {
    self = [super init];
    if (self) {
        _uid = dict[kAeropushConfigKeyUid] ?: @"";
        _projectId = dict[kAeropushConfigKeyProjectId] ?: @"";
        _appToken = dict[kAeropushConfigKeyAppToken] ?: @"";
        _sdkToken = dict[kAeropushConfigKeySdkToken] ?: @"";
        _appVersion = dict[kAeropushConfigKeyAppVersion] ?: @"";
        _filesDirectory = dict[kAeropushConfigKeyFilesDirectory] ?: @"";
        _publicSigningKey = dict[kAeropushConfigKeyPublicSigningKey] ?: @"";
    }
    return self;
}

- (NSDictionary *)toDictionary {
    return @{
        kAeropushConfigKeyUid: self.uid ?: @"",
        kAeropushConfigKeyProjectId: self.projectId ?: @"",
        kAeropushConfigKeyAppToken: self.appToken ?: @"",
        kAeropushConfigKeySdkToken: self.sdkToken ?: @"",
        kAeropushConfigKeyAppVersion: self.appVersion ?: @"",
        kAeropushConfigKeyFilesDirectory: self.filesDirectory ?: @"",
        kAeropushConfigKeyPublicSigningKey: self.publicSigningKey ?: @"",
        kAeropushConfigKeyPlatform: kAeropushPlatform,
    };
}

- (NSString *)toJSONString {
    NSError *error;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:[self toDictionary]
                                                       options:0
                                                         error:&error];
    if (!jsonData) {
        return @"{}";
    }
    return [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
}

#pragma mark - NSCoding

- (void)encodeWithCoder:(NSCoder *)coder {
    [coder encodeObject:self.uid forKey:kAeropushConfigKeyUid];
    [coder encodeObject:self.projectId forKey:kAeropushConfigKeyProjectId];
    [coder encodeObject:self.appToken forKey:kAeropushConfigKeyAppToken];
    [coder encodeObject:self.sdkToken forKey:kAeropushConfigKeySdkToken];
    [coder encodeObject:self.appVersion forKey:kAeropushConfigKeyAppVersion];
    [coder encodeObject:self.filesDirectory forKey:kAeropushConfigKeyFilesDirectory];
    [coder encodeObject:self.publicSigningKey forKey:kAeropushConfigKeyPublicSigningKey];
}

- (instancetype)initWithCoder:(NSCoder *)coder {
    self = [super init];
    if (self) {
        _uid = [coder decodeObjectForKey:kAeropushConfigKeyUid] ?: @"";
        _projectId = [coder decodeObjectForKey:kAeropushConfigKeyProjectId] ?: @"";
        _appToken = [coder decodeObjectForKey:kAeropushConfigKeyAppToken] ?: @"";
        _sdkToken = [coder decodeObjectForKey:kAeropushConfigKeySdkToken] ?: @"";
        _appVersion = [coder decodeObjectForKey:kAeropushConfigKeyAppVersion] ?: @"";
        _filesDirectory = [coder decodeObjectForKey:kAeropushConfigKeyFilesDirectory] ?: @"";
        _publicSigningKey = [coder decodeObjectForKey:kAeropushConfigKeyPublicSigningKey] ?: @"";
    }
    return self;
}

@end
