#import "AeropushSignatureVerification.h"
#import <CommonCrypto/CommonDigest.h>
#import <Security/Security.h>

@implementation AeropushSignatureVerification

+ (BOOL)verifyJWT:(NSString *)jwt withPublicKey:(NSString *)publicKey {
    if (!jwt || !publicKey || jwt.length == 0 || publicKey.length == 0) {
        return NO;
    }

    // Split JWT into parts
    NSArray *parts = [jwt componentsSeparatedByString:@"."];
    if (parts.count != 3) {
        NSLog(@"[Aeropush] Invalid JWT format: expected 3 parts, got %lu", (unsigned long)parts.count);
        return NO;
    }

    NSString *headerAndPayload = [NSString stringWithFormat:@"%@.%@", parts[0], parts[1]];
    NSString *signatureBase64 = parts[2];

    // Decode base64url signature
    NSData *signatureData = [self base64UrlDecode:signatureBase64];
    if (!signatureData) {
        NSLog(@"[Aeropush] Failed to decode JWT signature");
        return NO;
    }

    // Get data to verify
    NSData *dataToVerify = [headerAndPayload dataUsingEncoding:NSUTF8StringEncoding];
    if (!dataToVerify) {
        return NO;
    }

    // Parse public key
    SecKeyRef pubKey = [self parseRSAPublicKey:publicKey];
    if (!pubKey) {
        NSLog(@"[Aeropush] Failed to parse RSA public key");
        return NO;
    }

    // Verify RSA SHA-256 signature
    BOOL result = [self verifyRSASHA256:dataToVerify signature:signatureData publicKey:pubKey];
    CFRelease(pubKey);

    return result;
}

+ (NSString *)sha256HashOfFileAtPath:(NSString *)path {
    NSFileHandle *handle = [NSFileHandle fileHandleForReadingAtPath:path];
    if (!handle) return nil;

    CC_SHA256_CTX ctx;
    CC_SHA256_Init(&ctx);

    while (YES) {
        @autoreleasepool {
            NSData *data = [handle readDataOfLength:4096];
            if (data.length == 0) break;
            CC_SHA256_Update(&ctx, data.bytes, (CC_LONG)data.length);
        }
    }
    [handle closeFile];

    unsigned char digest[CC_SHA256_DIGEST_LENGTH];
    CC_SHA256_Final(digest, &ctx);

    NSMutableString *hash = [NSMutableString stringWithCapacity:CC_SHA256_DIGEST_LENGTH * 2];
    for (int i = 0; i < CC_SHA256_DIGEST_LENGTH; i++) {
        [hash appendFormat:@"%02x", digest[i]];
    }
    return [hash copy];
}

+ (NSString *)sha256HashOfString:(NSString *)input {
    if (!input) return nil;

    NSData *data = [input dataUsingEncoding:NSUTF8StringEncoding];
    unsigned char digest[CC_SHA256_DIGEST_LENGTH];
    CC_SHA256(data.bytes, (CC_LONG)data.length, digest);

    NSMutableString *hash = [NSMutableString stringWithCapacity:CC_SHA256_DIGEST_LENGTH * 2];
    for (int i = 0; i < CC_SHA256_DIGEST_LENGTH; i++) {
        [hash appendFormat:@"%02x", digest[i]];
    }
    return [hash copy];
}

+ (BOOL)verifyBundleIntegrity:(NSString *)bundleDir expectedHash:(NSString *)expectedHash {
    if (!bundleDir || !expectedHash || expectedHash.length == 0) {
        return NO;
    }

    // Hash all files in the bundle directory to create a manifest hash
    NSFileManager *fm = [NSFileManager defaultManager];
    NSError *error;
    NSArray *files = [fm contentsOfDirectoryAtPath:bundleDir error:&error];
    if (error || !files) {
        return NO;
    }

    // Sort files for deterministic ordering
    files = [files sortedArrayUsingSelector:@selector(compare:)];

    CC_SHA256_CTX ctx;
    CC_SHA256_Init(&ctx);

    for (NSString *file in files) {
        NSString *filePath = [bundleDir stringByAppendingPathComponent:file];
        BOOL isDir = NO;
        if ([fm fileExistsAtPath:filePath isDirectory:&isDir] && !isDir) {
            NSString *fileHash = [self sha256HashOfFileAtPath:filePath];
            if (fileHash) {
                NSString *entry = [NSString stringWithFormat:@"%@:%@", file, fileHash];
                NSData *entryData = [entry dataUsingEncoding:NSUTF8StringEncoding];
                CC_SHA256_Update(&ctx, entryData.bytes, (CC_LONG)entryData.length);
            }
        }
    }

    unsigned char digest[CC_SHA256_DIGEST_LENGTH];
    CC_SHA256_Final(digest, &ctx);

    NSMutableString *manifestHash = [NSMutableString stringWithCapacity:CC_SHA256_DIGEST_LENGTH * 2];
    for (int i = 0; i < CC_SHA256_DIGEST_LENGTH; i++) {
        [manifestHash appendFormat:@"%02x", digest[i]];
    }

    return [manifestHash isEqualToString:expectedHash];
}

#pragma mark - Private Helpers

+ (NSData *)base64UrlDecode:(NSString *)input {
    NSMutableString *base64 = [input mutableCopy];

    // Replace URL-safe characters
    [base64 replaceOccurrencesOfString:@"-" withString:@"+" options:0 range:NSMakeRange(0, base64.length)];
    [base64 replaceOccurrencesOfString:@"_" withString:@"/" options:0 range:NSMakeRange(0, base64.length)];

    // Pad with '='
    NSInteger remainder = base64.length % 4;
    if (remainder > 0) {
        for (NSInteger i = 0; i < (4 - remainder); i++) {
            [base64 appendString:@"="];
        }
    }

    return [[NSData alloc] initWithBase64EncodedString:base64 options:0];
}

+ (SecKeyRef)parseRSAPublicKey:(NSString *)pemKey {
    // Remove PEM header/footer and whitespace
    NSMutableString *stripped = [pemKey mutableCopy];
    [stripped replaceOccurrencesOfString:@"-----BEGIN PUBLIC KEY-----" withString:@"" options:0 range:NSMakeRange(0, stripped.length)];
    [stripped replaceOccurrencesOfString:@"-----END PUBLIC KEY-----" withString:@"" options:0 range:NSMakeRange(0, stripped.length)];
    [stripped replaceOccurrencesOfString:@"-----BEGIN RSA PUBLIC KEY-----" withString:@"" options:0 range:NSMakeRange(0, stripped.length)];
    [stripped replaceOccurrencesOfString:@"-----END RSA PUBLIC KEY-----" withString:@"" options:0 range:NSMakeRange(0, stripped.length)];
    [stripped replaceOccurrencesOfString:@"\n" withString:@"" options:0 range:NSMakeRange(0, stripped.length)];
    [stripped replaceOccurrencesOfString:@"\r" withString:@"" options:0 range:NSMakeRange(0, stripped.length)];
    [stripped replaceOccurrencesOfString:@" " withString:@"" options:0 range:NSMakeRange(0, stripped.length)];

    NSData *keyData = [[NSData alloc] initWithBase64EncodedString:stripped options:0];
    if (!keyData) {
        return NULL;
    }

    NSDictionary *attributes = @{
        (__bridge NSString *)kSecAttrKeyType: (__bridge NSString *)kSecAttrKeyTypeRSA,
        (__bridge NSString *)kSecAttrKeyClass: (__bridge NSString *)kSecAttrKeyClassPublic,
        (__bridge NSString *)kSecAttrKeySizeInBits: @2048,
    };

    CFErrorRef cfError = NULL;
    SecKeyRef key = SecKeyCreateWithData((__bridge CFDataRef)keyData,
                                         (__bridge CFDictionaryRef)attributes,
                                         &cfError);

    if (cfError) {
        NSLog(@"[Aeropush] Error creating public key: %@", (__bridge NSError *)cfError);
        CFRelease(cfError);
        return NULL;
    }

    return key;
}

+ (BOOL)verifyRSASHA256:(NSData *)data signature:(NSData *)signature publicKey:(SecKeyRef)publicKey {
    if (!data || !signature || !publicKey) {
        return NO;
    }

    SecKeyAlgorithm algorithm = kSecKeyAlgorithmRSASignatureMessagePKCS1v15SHA256;

    if (!SecKeyIsAlgorithmSupported(publicKey, kSecKeyOperationTypeVerify, algorithm)) {
        NSLog(@"[Aeropush] RSA SHA-256 verification not supported");
        return NO;
    }

    CFErrorRef cfError = NULL;
    Boolean result = SecKeyVerifySignature(publicKey,
                                           algorithm,
                                           (__bridge CFDataRef)data,
                                           (__bridge CFDataRef)signature,
                                           &cfError);

    if (cfError) {
        NSLog(@"[Aeropush] Signature verification error: %@", (__bridge NSError *)cfError);
        CFRelease(cfError);
    }

    return (BOOL)result;
}

@end
