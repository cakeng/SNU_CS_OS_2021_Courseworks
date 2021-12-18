#include <stdio.h>
#include <unistd.h>
#include <stdlib.h>
#include <stdint.h>
#include <errno.h>
#include <sys/syscall.h>
#include <linux/types.h>
#include <linux/sched.h>
#include <bits/types/struct_sched_param.h>

struct gps_location loc 
{
    int lat_integer;
    int lat_fractional;
    int lng_integer;
    int lng_fractional;
    int accuracy;
}
int main
{
    


}