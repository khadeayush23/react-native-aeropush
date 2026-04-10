#import <Foundation/Foundation.h>

@interface AeropushConfig : NSObject <NSCoding>

@property (nonatomic, copy) NSString *uid;
@property (nonatomic, copy) NSString *projectId;
@property (nonatomic, copy) NSString *appToken;
@property (nonatomic, copy) NSString *sdkToken;
@property (nonatomic, copy) NSString *appVersion;
@property (nonatomic, copy) NSString *filesDirectory;
@property (nonatomic, copy) NSString *publicSigningKey;

- (instancetype)initWithDictionary:(NSDictionary *)dict;
- (NSDictionary *)toDictionary;
- (NSString *)toJSONString;

@end
