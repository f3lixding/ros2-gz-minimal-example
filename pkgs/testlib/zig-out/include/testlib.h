#ifndef CONTROLLER_H
#define CONTROLLER_H

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

void printToStdout(const char *input);

#ifdef __cplusplus
}
#endif

#endif
