#include <stdio.h>
#include <unistd.h>
#include <stdlib.h>
#include <stdint.h>
#include <errno.h>
#include <sys/syscall.h>
#include <linux/types.h>
#include <linux/sched.h>
#include <bits/types/struct_sched_param.h>

typedef struct gps_location {
    int lat_integer;
    int lat_fractional;
    int lng_integer;
    int lng_fractional;
    int accuracy;
} gps_location;
int main(int argc, char* argv[])
{
    if (argc != 2)
    {
        printf("wrong # of args");
        return 1;
    }
    else
    {
        gps_location loc = 
        {
            .lat_integer = -1,
            .lat_fractional = -1,
            .lng_integer = -1,
            .lng_fractional = -1,
            .accuracy = -1
        };
        int returnVal = syscall(399, argv[1], &loc);

        int latitude = loc.lat_integer*1000000 + loc.lat_fractional;
        int longtitude = loc.lng_integer*1000000 + loc.lng_fractional;

        printf("latitude: %d.%06d, longtitude: %d.%06d, accuracy: %d m\n", latitude/1000000, abs(latitude)%1000000, longtitude/1000000, abs(longtitude)%100000, loc.accuracy);

        printf("Google_link: www.google.com/maps/search/%d.%06d,%d.%06d\n", latitude/1000000, abs(latitude)%1000000, longtitude/1000000, abs(longtitude)%1000000);
        
        return 0;
    }
   
    


}