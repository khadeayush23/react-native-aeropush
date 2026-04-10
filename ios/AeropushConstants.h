#ifndef AeropushConstants_h
#define AeropushConstants_h

#import <Foundation/Foundation.h>

// Module name
static NSString *const kAeropushModuleName = @"Aeropush";

// Event names
static NSString *const kAeropushNativeEvent = @"AEROPUSH_NATIVE_EVENT";

// API
static NSString *const kAeropushApiBaseUrl = @"https://api.example.com";
static NSString *const kAeropushSyncEndpoint = @"/v1/sync";
static NSString *const kAeropushTokenEndpoint = @"/v1/token";

// Directory names
static NSString *const kAeropushProdDir = @"AeropushProd";
static NSString *const kAeropushStageDir = @"AeropushStage";
static NSString *const kAeropushNewDir = @"AeropushNew";
static NSString *const kAeropushStableDir = @"AeropushStable";

// File names
static NSString *const kAeropushBundleFilename = @"index.bundle";
static NSString *const kAeropushManifestFilename = @"manifest.json";
static NSString *const kAeropushDownloadZipFilename = @"download.zip";
static NSString *const kAeropushSignatureFilename = @"signature.jwt";

// NSUserDefaults keys prefix
static NSString *const kAeropushDefaultsPrefix = @"aeropush_";
static NSString *const kAeropushDefaultsConfig = @"aeropush_config";
static NSString *const kAeropushDefaultsMeta = @"aeropush_meta";
static NSString *const kAeropushDefaultsEvents = @"aeropush_events";
static NSString *const kAeropushDefaultsCrashMarker = @"aeropush_crash_marker";

// Limits
static const NSInteger kAeropushMaxLaunchCount = 3;
static const NSInteger kAeropushMaxEvents = 60;
static const NSInteger kAeropushEventBatchSize = 9;
static const NSTimeInterval kAeropushRollbackTTL = 6.0 * 60.0 * 60.0; // 6 hours in seconds

// Platform identifier
static NSString *const kAeropushPlatform = @"ios";

// HTTP Headers
static NSString *const kAeropushHeaderContentType = @"Content-Type";
static NSString *const kAeropushHeaderAuthorization = @"Authorization";
static NSString *const kAeropushHeaderAppToken = @"X-App-Token";
static NSString *const kAeropushContentTypeJSON = @"application/json";

#endif /* AeropushConstants_h */
