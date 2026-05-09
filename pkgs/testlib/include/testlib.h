#ifndef CONTROLLER_H
#define CONTROLLER_H

#include <cstdint>
#include <stddef.h>

#ifdef __cplusplus
extern "C" {
#endif

typedef struct LaserScanFFISafe {
  float angle_min;
  float angle_max;
  float angle_increment;
  float time_increment;
  float scan_time;
  float range_min;
  float range_max;
  const float *ranges;
  size_t ranges_len;
} LaserScanFFISafe;

void handleMessage(uint64_t handler_ptr, LaserScanFFISafe msg);

uint64_t spawnHandler();

#ifdef __cplusplus
}
#endif

#endif
