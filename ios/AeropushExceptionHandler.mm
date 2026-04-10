#import "AeropushExceptionHandler.h"
#import "AeropushStateManager.h"
#import "AeropushSlotManager.h"
#import "AeropushEventHandler.h"
#import "AeropushConstants.h"
#import "AeropushMetaConstants.h"
#import <signal.h>

// Store previous handlers for chaining
static NSUncaughtExceptionHandler *sPreviousExceptionHandler = nil;
static struct sigaction sPreviousSIGABRT;
static struct sigaction sPreviousSIGSEGV;
static struct sigaction sPreviousSIGBUS;
static struct sigaction sPreviousSIGFPE;
static struct sigaction sPreviousSIGILL;

static void AeropushHandleException(NSException *exception);
static void AeropushHandleSignal(int signal);

@implementation AeropushExceptionHandler

+ (void)install {
    // Install ObjC exception handler
    sPreviousExceptionHandler = NSGetUncaughtExceptionHandler();
    NSSetUncaughtExceptionHandler(&AeropushHandleException);

    // Install signal handlers
    struct sigaction action;
    memset(&action, 0, sizeof(action));
    action.sa_handler = &AeropushHandleSignal;
    sigemptyset(&action.sa_mask);
    action.sa_flags = 0;

    sigaction(SIGABRT, &action, &sPreviousSIGABRT);
    sigaction(SIGSEGV, &action, &sPreviousSIGSEGV);
    sigaction(SIGBUS, &action, &sPreviousSIGBUS);
    sigaction(SIGFPE, &action, &sPreviousSIGFPE);
    sigaction(SIGILL, &action, &sPreviousSIGILL);

    NSLog(@"[Aeropush] Exception handler installed");
}

+ (void)uninstall {
    NSSetUncaughtExceptionHandler(sPreviousExceptionHandler);
    sPreviousExceptionHandler = nil;

    sigaction(SIGABRT, &sPreviousSIGABRT, NULL);
    sigaction(SIGSEGV, &sPreviousSIGSEGV, NULL);
    sigaction(SIGBUS, &sPreviousSIGBUS, NULL);
    sigaction(SIGFPE, &sPreviousSIGFPE, NULL);
    sigaction(SIGILL, &sPreviousSIGILL, NULL);

    NSLog(@"[Aeropush] Exception handler uninstalled");
}

+ (void)setCrashMarker {
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:kAeropushDefaultsCrashMarker];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

+ (void)clearCrashMarker {
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:kAeropushDefaultsCrashMarker];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

+ (BOOL)hasCrashMarker {
    return [[NSUserDefaults standardUserDefaults] boolForKey:kAeropushDefaultsCrashMarker];
}

+ (void)handlePostCrashRollbackIfNeeded {
    if (![self hasCrashMarker]) {
        return;
    }

    NSLog(@"[Aeropush] Crash marker detected from previous session");

    // Clear the marker immediately
    [self clearCrashMarker];

    AeropushStateManager *state = [AeropushStateManager shared];

    // If we were running an Aeropush bundle (prod or stage with NEW state), roll it back
    if (state.meta.switchState == AeropushSwitchStateProd &&
        state.meta.prodSlotState == AeropushSlotStateNew) {
        NSLog(@"[Aeropush] Rolling back prod due to crash");
        [AeropushSlotManager fallbackProd];

        [[AeropushEventHandler shared] addEvent:@"CRASH_ROLLBACK_PROD" payload:@{
            @"hash": state.meta.prodHash ?: @""
        }];
    } else if (state.meta.switchState == AeropushSwitchStateStage &&
               state.meta.stageSlotState == AeropushSlotStateNew) {
        NSLog(@"[Aeropush] Rolling back stage due to crash");
        [AeropushSlotManager fallbackStage];

        [[AeropushEventHandler shared] addEvent:@"CRASH_ROLLBACK_STAGE" payload:@{
            @"hash": state.meta.stageHash ?: @""
        }];
    }
}

#pragma mark - Private

+ (void)onCrashDetected {
    // This runs in a crash context, so keep it minimal
    AeropushStateManager *state = [AeropushStateManager shared];

    // Only set crash marker if we're running an Aeropush bundle
    if (state.meta.switchState != AeropushSwitchStateOff) {
        if ((state.meta.switchState == AeropushSwitchStateProd &&
             state.meta.prodSlotState != AeropushSlotStateDefault) ||
            (state.meta.switchState == AeropushSwitchStateStage &&
             state.meta.stageSlotState != AeropushSlotStateDefault)) {
            [self setCrashMarker];
        }
    }
}

@end

#pragma mark - C Handlers

static void AeropushHandleException(NSException *exception) {
    NSLog(@"[Aeropush] Uncaught exception: %@ - %@", exception.name, exception.reason);
    [AeropushExceptionHandler onCrashDetected];

    // Chain to previous handler
    if (sPreviousExceptionHandler) {
        sPreviousExceptionHandler(exception);
    }
}

static void AeropushHandleSignal(int sig) {
    NSLog(@"[Aeropush] Caught signal: %d", sig);
    [AeropushExceptionHandler onCrashDetected];

    // Chain to previous handler
    struct sigaction *previous = NULL;
    switch (sig) {
        case SIGABRT: previous = &sPreviousSIGABRT; break;
        case SIGSEGV: previous = &sPreviousSIGSEGV; break;
        case SIGBUS:  previous = &sPreviousSIGBUS;  break;
        case SIGFPE:  previous = &sPreviousSIGFPE;  break;
        case SIGILL:  previous = &sPreviousSIGILL;  break;
        default: break;
    }

    if (previous && previous->sa_handler != SIG_DFL && previous->sa_handler != SIG_IGN) {
        previous->sa_handler(sig);
    } else {
        // Re-raise with default handler
        signal(sig, SIG_DFL);
        raise(sig);
    }
}
