#import <Foundation/Foundation.h>

@interface AeropushSignatureVerification : NSObject

/// Verify a JWT signature against a public RSA key.
/// @param jwt The JWT string to verify.
/// @param publicKey The PEM-encoded RSA public key.
/// @return YES if the signature is valid.
+ (BOOL)verifyJWT:(NSString *)jwt withPublicKey:(NSString *)publicKey;

/// Compute SHA-256 hash of a file.
/// @param path Path to the file.
/// @return Hex-encoded SHA-256 hash string.
+ (NSString *)sha256HashOfFileAtPath:(NSString *)path;

/// Compute SHA-256 hash of a string.
/// @param input The input string.
/// @return Hex-encoded SHA-256 hash string.
+ (NSString *)sha256HashOfString:(NSString *)input;

/// Verify bundle integrity by checking the manifest hash against bundle files.
/// @param bundleDir Path to the bundle directory.
/// @param expectedHash Expected hash from the manifest.
/// @return YES if the bundle integrity is verified.
+ (BOOL)verifyBundleIntegrity:(NSString *)bundleDir expectedHash:(NSString *)expectedHash;

@end
