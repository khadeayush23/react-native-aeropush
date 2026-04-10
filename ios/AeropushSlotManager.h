#import <Foundation/Foundation.h>
#import "AeropushMetaConstants.h"

@interface AeropushSlotManager : NSObject

/// Rollback prod slot to DEFAULT state, clearing NEW/STABLE directories.
+ (void)rollbackProd;

/// Rollback stage slot to DEFAULT state, clearing NEW/STABLE directories.
+ (void)rollbackStage;

/// Fallback from NEW to STABLE if STABLE exists, otherwise to DEFAULT.
+ (void)fallbackProd;

/// Fallback from NEW to STABLE if STABLE exists, otherwise to DEFAULT.
+ (void)fallbackStage;

/// Stabilize prod: move NEW to STABLE.
+ (void)stabilizeProd;

/// Stabilize stage: move NEW to STABLE.
+ (void)stabilizeStage;

/// Promote a downloaded bundle to the NEW slot for prod.
+ (BOOL)promoteToProdNew:(NSString *)sourcePath hash:(NSString *)hash version:(NSString *)version;

/// Promote a downloaded bundle to the NEW slot for stage.
+ (BOOL)promoteToStageNew:(NSString *)sourcePath hash:(NSString *)hash version:(NSString *)version;

@end
