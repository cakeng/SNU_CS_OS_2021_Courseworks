#include <linux/gps.h>

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
	printk ("DEBUG: GPS Current Status: LAT:%d.%d, LONG: %d.%d, ACC: %d.\n", 
        current_loc.lat_integer, current_loc.lat_fractional, 
            current_loc.lng_integer, current_loc.lng_fractional,
                current_loc.accuracy);
	mutex_unlock(&gps_mutex);
    #endif
}

long do_set_gps_location(gps_location* loc)
{
    gps_location kloc;
	if(copy_from_user(&kloc, loc, sizeof(gps_location)))
    {
        #if __GPS_DEBUG
        printk ("DEBUG: set_gps_location called.\n");
        print_gps();
        #endif
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
	if(kloc.lat_fractional < 0 || kloc.lat_fractional > 999999)
    {
        return -EINVAL;
    }
	if(kloc.lng_fractional < 0 || kloc.lng_fractional > 999999)
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

