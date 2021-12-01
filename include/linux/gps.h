#ifndef __LINUX_GPS
#define __LINUX_GPS

#include <linux/types.h>
#include <linux/sched.h>
#include <linux/list.h>
#include <linux/errno.h>
#include <linux/syscalls.h>
#include <linux/mutex.h>

#define __GPS_DEBUG 1

typedef struct gps_location {
    int lat_integer;
    int lat_fractional;
    int lng_integer;
    int lng_fractional;
    int accuracy;
} gps_location;

extern gps_location current_loc;

#endif // #define __LINUX_GPS