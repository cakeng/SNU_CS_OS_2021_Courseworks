#ifndef __LINUX_GPS_H
#define __LINUX_GPS_H

#include <linux/mutex.h>

#define __GPS_DEBUG 1
#define __GPS_FRAC_MAX 1000000UL
#define __GPS_EARTH_RAD 6371000UL // In meters.

typedef struct gps_location {
    int lat_integer;
    int lat_fractional;
    int lng_integer;
    int lng_fractional;
    int accuracy;
} gps_location;

extern gps_location current_loc;
extern struct mutex gps_mutex;

extern long get_distance (gps_location* loc1, gps_location* loc2);

#endif // #define __LINUX_GPS_H