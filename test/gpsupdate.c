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
    int syscallNum;
    int returnVal;
    if (argc < 2)
    {
        printf("Enter syscall number and its arguments.\n");
        printf("Available syscalls - sys_set_gps_location 398, sys_get_gps_location 399.\n");
        return 1;
    }
    syscallNum = 398;
    if (syscallNum == 398)
    {
        if (argc < 6)
        {
            printf("Not enough arguments! Enter lat_int, lat_frac, long_int, long_frac, accuracy.\n");
            return 1;
        }
        gps_location loc = 
        {
            .lat_integer = atoi(argv[1]),
            .lat_fractional = atoi(argv[2]),
            .lng_integer = atoi(argv[3]),
            .lng_fractional = atoi(argv[4]),
            .accuracy = atoi(argv[5])
        };
        printf("Calling syscall sys_set_rotation.\n");
        returnVal = syscall(398, &loc);
        printf("Syscall sys_set_rotation returned - %d.\n", returnVal);
    }
    else
    {
        printf("Unsupported syscall. Syscall number - %d\n", syscallNum);
        return 1;
    }
    if (errno == ENOSYS)
    {
        printf("ENOSYS received. No system support.\n");
    }
    else if (errno == EPERM)
    {
        printf("EPERM received. No permission.\n");
    }
    else if (errno == ESRCH)
    {
        printf("ESRCH received. No process found.\n");
    }
    else if (errno == EINVAL)
    {
        printf("EINVAL received. Not a valid parameter.\n");
    }
    else if (errno == EACCES)
    {
        printf("EACCES received. No Permission.\n");
    }
    else if (errno == EFAULT)
    {
        printf("EFAULT received.\n");
    }
    else if (errno == ENODEV)
    {
        printf("EFAULT received. No GPS Embedding.\n");
    }
    return 0;
}