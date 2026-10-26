/*
 * Read-only Android NDK sensor inventory and passive sampling probe.
 *
 * Build with the Android NDK and run from an Android process that can access
 * ASensorManager. The program does not
 * request permissions or change device settings. It writes one JSON document
 * to stdout and diagnostics to stderr.
 */

#include <android/looper.h>
#include <android/sensor.h>
#include <errno.h>
#include <inttypes.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>

#define SAMPLE_SECONDS 5
#define MAX_TRACKED_TYPE 64

static void json_string(const char *value) {
    const unsigned char *p = (const unsigned char *)(value ? value : "");
    putchar('"');
    for (; *p; ++p) {
        switch (*p) {
            case '"': fputs("\\\"", stdout); break;
            case '\\': fputs("\\\\", stdout); break;
            case '\b': fputs("\\b", stdout); break;
            case '\f': fputs("\\f", stdout); break;
            case '\n': fputs("\\n", stdout); break;
            case '\r': fputs("\\r", stdout); break;
            case '\t': fputs("\\t", stdout); break;
            default:
                if (*p < 0x20) printf("\\u%04x", *p);
                else putchar(*p);
        }
    }
    putchar('"');
}

static int64_t monotonic_ms(void) {
    struct timespec ts;
    if (clock_gettime(CLOCK_MONOTONIC, &ts) != 0) return -1;
    return (int64_t)ts.tv_sec * 1000 + ts.tv_nsec / 1000000;
}

int main(void) {
    ASensorManager *manager = ASensorManager_getInstanceForPackage("com.termux");
    ASensorList list = NULL;
    int counts[MAX_TRACKED_TYPE + 1] = {0};
    int available[MAX_TRACKED_TYPE + 1] = {0};
    int configured[MAX_TRACKED_TYPE + 1] = {0};
    int sensor_count;
    int enabled = 0;
    int first;
    int i;

    if (!manager) {
        fputs("sensor manager unavailable\n", stderr);
        return 2;
    }

    sensor_count = ASensorManager_getSensorList(manager, &list);
    if (sensor_count < 0 || !list) {
        fprintf(stderr, "sensor enumeration failed: %d\n", sensor_count);
        return 2;
    }

    ALooper *looper = ALooper_prepare(ALOOPER_PREPARE_ALLOW_NON_CALLBACKS);
    if (!looper) {
        fputs("looper creation failed\n", stderr);
        return 2;
    }

    ASensorEventQueue *queue = ASensorManager_createEventQueue(
        manager, looper, 1, NULL, NULL);
    if (!queue) {
        fputs("sensor event queue creation failed\n", stderr);
        return 2;
    }

    for (i = 0; i < sensor_count; ++i) {
        int type = ASensor_getType(list[i]);
        if (type >= 0 && type <= MAX_TRACKED_TYPE) available[type] = 1;
    }

    /* Passive sampling only. Event-driven sensors may legitimately emit zero. */
    const int targets[] = {
        ASENSOR_TYPE_ACCELEROMETER,
        ASENSOR_TYPE_MAGNETIC_FIELD,
        ASENSOR_TYPE_GYROSCOPE,
        ASENSOR_TYPE_LIGHT,
        ASENSOR_TYPE_PRESSURE,
        ASENSOR_TYPE_PROXIMITY,
        ASENSOR_TYPE_GRAVITY,
        ASENSOR_TYPE_LINEAR_ACCELERATION,
        ASENSOR_TYPE_ROTATION_VECTOR,
        ASENSOR_TYPE_STEP_COUNTER
    };
    const size_t target_count = sizeof(targets) / sizeof(targets[0]);

    for (i = 0; i < (int)target_count; ++i) {
        const ASensor *sensor = ASensorManager_getDefaultSensor(manager, targets[i]);
        if (!sensor) continue;
        if (ASensorEventQueue_enableSensor(queue, sensor) != 0) continue;
        int delay = ASensor_getMinDelay(sensor);
        if (delay <= 0 || delay < 20000) delay = 20000;
        if (ASensorEventQueue_setEventRate(queue, sensor, delay) != 0) {
            ASensorEventQueue_disableSensor(queue, sensor);
            continue;
        }
        configured[targets[i]] = 1;
        ++enabled;
    }

    int64_t started = monotonic_ms();
    if (started < 0) {
        fputs("monotonic clock unavailable\n", stderr);
        ASensorManager_destroyEventQueue(manager, queue);
        return 2;
    }
    int64_t deadline = started + SAMPLE_SECONDS * 1000;
    int64_t now = started;
    while (enabled > 0 && now < deadline) {
        ASensorEvent events[32];
        int ident = ALooper_pollOnce(250, NULL, NULL, NULL);
        if (ident < 0 && ident != ALOOPER_POLL_TIMEOUT && ident != ALOOPER_POLL_WAKE) {
            fprintf(stderr, "looper poll failed: %d\n", ident);
            ASensorManager_destroyEventQueue(manager, queue);
            return 2;
        }
        ssize_t n;
        while ((n = ASensorEventQueue_getEvents(queue, events, 32)) > 0) {
            ssize_t j;
            for (j = 0; j < n; ++j) {
                int type = events[j].type;
                if (type >= 0 && type <= MAX_TRACKED_TYPE) ++counts[type];
            }
        }
        if (n < 0 && errno != EAGAIN) {
            fprintf(stderr, "sensor read failed: %s\n", strerror(errno));
            ASensorManager_destroyEventQueue(manager, queue);
            return 2;
        }
        now = monotonic_ms();
        if (now < 0) {
            fputs("monotonic clock unavailable\n", stderr);
            ASensorManager_destroyEventQueue(manager, queue);
            return 2;
        }
    }

    ASensorManager_destroyEventQueue(manager, queue);

    printf("{\"schema_version\":1,\"probe\":\"ndk-asensormanager-passive\",");
    printf("\"sample_seconds\":%d,\"sensor_count\":%d,", SAMPLE_SECONDS, sensor_count);
    fputs("\"inventory\":[", stdout);
    first = 1;
    for (i = 0; i < sensor_count; ++i) {
        const ASensor *sensor = list[i];
        if (!first) putchar(',');
        first = 0;
        fputs("{\"name\":", stdout); json_string(ASensor_getName(sensor));
        fputs(",\"vendor\":", stdout); json_string(ASensor_getVendor(sensor));
        printf(",\"type\":%d,\"resolution\":%.9g,\"min_delay_us\":%d}",
               ASensor_getType(sensor), ASensor_getResolution(sensor),
               ASensor_getMinDelay(sensor));
    }
    fputs("],\"targets\":[", stdout);
    for (i = 0; i < (int)target_count; ++i) {
        int type = targets[i];
        const char *verdict;
        if (i) putchar(',');
        if (!available[type]) verdict = "NOT_PRESENT";
        else if (!configured[type]) verdict = "CONFIG_ERROR";
        else if (counts[type] > 0) verdict = "PASS";
        else verdict = "NOT_TRIGGERED";
        printf("{\"type\":%d,\"available\":%s,\"samples\":%d,\"verdict\":",
               type, available[type] ? "true" : "false", counts[type]);
        json_string(verdict);
        putchar('}');
    }
    printf("],\"elapsed_ms\":%" PRId64 "}\n", now - started);
    return 0;
}
