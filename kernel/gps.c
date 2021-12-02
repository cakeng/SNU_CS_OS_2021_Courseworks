#include <linux/gps.h>
#include <linux/types.h>
#include <linux/errno.h>
#include <linux/syscalls.h>

#include "gps_sec_arctan.h"

DEFINE_MUTEX(gps_mutex);

gps_location current_loc = 
{
    .lat_integer = 0,
    .lat_fractional = 0,
    .lng_integer = 0,
    .lng_fractional = 0,
    .accuracy = 0
};

void print_gps(void)
{
    #if __GPS_DEBUG
    mutex_lock(&gps_mutex);
	printk ("DEBUG: GPS Current Status: LAT:%d.(%d/1000000), LONG: %d.(%d/1000000), ACC: %d.\n", 
        current_loc.lat_integer, current_loc.lat_fractional, 
            current_loc.lng_integer, current_loc.lng_fractional,
                current_loc.accuracy);
	mutex_unlock(&gps_mutex);
    #endif
}

// Assumes Cartesian coordinate system
long get_distance (gps_location* loc1, gps_location* loc2)
{
    long d = 0;
    long d_lat = (loc1->lat_integer - loc2->lat_integer) *__GPS_FRAC_MAX
        + loc1->lat_fractional - loc2->lat_fractional;
    long d_lng = (loc1->lng_integer - loc2->lng_integer) *__GPS_FRAC_MAX
        + loc1->lng_fractional - loc2->lng_fractional;
    unsigned long cos_idx, d_x_cos, d_x, d_y, d_tan, cos_lat;
    if (d_lat < 0)
    {
        d_lat = -d_lat;
    }
    if (d_lat > 180*__GPS_FRAC_MAX)
    {
        d_lat -= 180*__GPS_FRAC_MAX;
    }
    if (d_lng < 0)
    {
        d_lng = -d_lng;
    }
    if (d_lng > 180*__GPS_FRAC_MAX)
    {
        d_lng -= 180*__GPS_FRAC_MAX;
    }
    cos_lat = ((loc1->lat_integer + loc2->lat_integer) *__GPS_FRAC_MAX + loc1->lat_fractional + loc2->lat_fractional) / 2;
    if (cos_lat < 0)
    {
        cos_lat = -cos_lat;
    }
    if (cos_lat > 90 * __GPS_FRAC_MAX)
    {
        cos_idx = 180 * __GPS_FRAC_MAX - cos_lat;
    }
    else
    {
        cos_idx = cos_lat;
    }
    
    if (cos_idx > 89990000)
    {
        d_x_cos = 0;
    }
    else
    {
        d_x_cos = cos_arr[cos_idx / 10000];
    }
    d_x = ((2UL * 3141592UL * __GPS_EARTH_RAD) / __GPS_FRAC_MAX) * (unsigned long)d_lng / (360UL * __GPS_FRAC_MAX) * d_x_cos / __GPS_FRAC_MAX; // In meters.
    d_y = ((2UL * 3141592UL * __GPS_EARTH_RAD) / __GPS_FRAC_MAX) * (unsigned long)d_lat / (360UL * __GPS_FRAC_MAX); // In meters.
    if (d_x == 0)
    {
        d_tan = 109999 + 1;
    }
    else
    {
        d_tan = d_y * 10000 / d_x;
    }
    if (d_tan <= 10000)
    {
        d = sec_arctan[d_tan] * d_x / __GPS_FRAC_MAX;
    }
    else if (d_tan > 109999)
    {
        d = d_y;
    }
    else
    {
        d = sec_arctan[(d_tan - 10000) / 10 + 10000] * d_x / __GPS_FRAC_MAX;
    }
    // #if __GPS_DEBUG
    // printk ("DEBUG: gps get_distance d_lat: %ld, d_lng: %ld, cos_idx: %ld, d_x_cos: %ld, d_x: %ld, d_y: %ld, d_tan: %ld.\n",
    //     d_lat, d_lng, cos_idx / 10000, d_x_cos, d_x, d_y, d_tan);
    // #endif
    return d;
}

long do_set_gps_location(gps_location* loc)
{
    gps_location kloc;
    #if __GPS_DEBUG
    printk ("DEBUG: set_gps_location called.\n");
    print_gps();
    #endif
	if(copy_from_user(&kloc, loc, sizeof(gps_location)))
    {
        return -EFAULT;
    }
	if(kloc.lat_integer < -90 || kloc.lat_integer > 90)
    {
        return -EINVAL;
    }
	if(kloc.lng_integer < -180 || kloc.lng_integer > 180)
    {
        return -EINVAL;
    }
	if(kloc.lat_fractional < 0 || kloc.lat_fractional > __GPS_FRAC_MAX-1)
    {
        return -EINVAL;
    }
	if(kloc.lng_fractional < 0 || kloc.lng_fractional > __GPS_FRAC_MAX-1)
    {
        return -EINVAL;
    }
	if(kloc.lat_integer == 90 && kloc.lat_fractional != 0)
    {
        return -EINVAL;
    }
	if(kloc.lng_integer == 180 && kloc.lng_fractional != 0)
    {
        return -EINVAL;
    }
	if(kloc.accuracy < 0)
    {
        return -EINVAL;
    }
    #if __GPS_DEBUG
    printk ("DEBUG: set_gps_location distance from old location: %ldm.\n", get_distance(&kloc, &current_loc));
    #endif
	mutex_lock(&gps_mutex);
	memcpy(&current_loc, &kloc, sizeof(gps_location));
	mutex_unlock(&gps_mutex);
    #if __GPS_DEBUG
    printk ("DEBUG: set_gps_location complete.\n");
    print_gps();
    #endif
	return 0;
}


SYSCALL_DEFINE1(set_gps_location, struct gps_location __user *, loc)
{
	return do_set_gps_location(loc);
}

