#include <jni.h>
#include <signal.h>
#include <string.h>
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <fcntl.h>
#include <time.h>
#include <android/log.h>

#define LOG_TAG "AeropushCrash"
#define LOGD(...) __android_log_print(ANDROID_LOG_DEBUG, LOG_TAG, __VA_ARGS__)
#define LOGE(...) __android_log_print(ANDROID_LOG_ERROR, LOG_TAG, __VA_ARGS__)

static const int HANDLED_SIGNALS[] = {SIGABRT, SIGSEGV, SIGILL, SIGBUS, SIGFPE};
static const int NUM_SIGNALS = sizeof(HANDLED_SIGNALS) / sizeof(HANDLED_SIGNALS[0]);

static struct sigaction old_handlers[NUM_SIGNALS];
static char crash_marker_path[512] = {0};

static const char* signal_name(int sig) {
    switch (sig) {
        case SIGABRT: return "SIGABRT";
        case SIGSEGV: return "SIGSEGV";
        case SIGILL:  return "SIGILL";
        case SIGBUS:  return "SIGBUS";
        case SIGFPE:  return "SIGFPE";
        default:      return "UNKNOWN";
    }
}

static void write_crash_marker(int sig) {
    if (crash_marker_path[0] == '\0') return;

    int fd = open(crash_marker_path, O_WRONLY | O_CREAT | O_TRUNC, 0644);
    if (fd < 0) return;

    struct timespec ts;
    clock_gettime(CLOCK_REALTIME, &ts);
    long long timestamp_ms = (long long)ts.tv_sec * 1000LL + (long long)ts.tv_nsec / 1000000LL;

    char buf[256];
    int len = snprintf(buf, sizeof(buf),
        "{\"type\":\"native_signal\",\"signal\":\"%s\",\"signum\":%d,\"timestamp\":%lld}",
        signal_name(sig), sig, timestamp_ms);

    if (len > 0 && len < (int)sizeof(buf)) {
        write(fd, buf, (size_t)len);
    }

    close(fd);
}

static void aeropush_signal_handler(int sig, siginfo_t* info, void* ucontext) {
    LOGE("Caught signal %d (%s)", sig, signal_name(sig));

    // Write crash marker file (async-signal-safe operations only)
    write_crash_marker(sig);

    // Chain to the previous handler
    for (int i = 0; i < NUM_SIGNALS; i++) {
        if (HANDLED_SIGNALS[i] == sig) {
            struct sigaction* old = &old_handlers[i];
            if (old->sa_flags & SA_SIGINFO) {
                if (old->sa_sigaction != NULL) {
                    old->sa_sigaction(sig, info, ucontext);
                    return;
                }
            } else {
                if (old->sa_handler != SIG_DFL && old->sa_handler != SIG_IGN && old->sa_handler != NULL) {
                    old->sa_handler(sig);
                    return;
                }
            }
            break;
        }
    }

    // If no previous handler, re-raise with default behavior
    struct sigaction sa;
    memset(&sa, 0, sizeof(sa));
    sa.sa_handler = SIG_DFL;
    sigaction(sig, &sa, NULL);
    raise(sig);
}

extern "C"
JNIEXPORT void JNICALL
Java_com_aeropush_utils_AeropushExceptionHandler_initNativeSignalHandler(
    JNIEnv* env,
    jclass /* clazz */,
    jstring crashMarkerPath) {

    const char* path = env->GetStringUTFChars(crashMarkerPath, NULL);
    if (path == NULL) return;

    size_t path_len = strlen(path);
    if (path_len >= sizeof(crash_marker_path)) {
        env->ReleaseStringUTFChars(crashMarkerPath, path);
        LOGE("Crash marker path too long");
        return;
    }
    strncpy(crash_marker_path, path, sizeof(crash_marker_path) - 1);
    crash_marker_path[sizeof(crash_marker_path) - 1] = '\0';
    env->ReleaseStringUTFChars(crashMarkerPath, path);

    LOGD("Installing signal handlers, crash marker: %s", crash_marker_path);

    struct sigaction sa;
    memset(&sa, 0, sizeof(sa));
    sa.sa_sigaction = aeropush_signal_handler;
    sa.sa_flags = SA_SIGINFO | SA_ONSTACK;
    sigemptyset(&sa.sa_mask);

    for (int i = 0; i < NUM_SIGNALS; i++) {
        if (sigaction(HANDLED_SIGNALS[i], &sa, &old_handlers[i]) != 0) {
            LOGE("Failed to install handler for signal %d", HANDLED_SIGNALS[i]);
        }
    }

    LOGD("Signal handlers installed successfully");
}
