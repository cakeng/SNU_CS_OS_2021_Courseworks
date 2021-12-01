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

/* Related Syscalls
asmlinkage long sys_set_rotation(int degree); 398
asmlinkage long sys_rotlock_read(int degree, int range); 399
asmlinkage long sys_rotlock_write(int degree, int range); 400
asmlinkage long sys_rotunlock_read(int degree, int range); 401
asmlinkage long sys_rotunlock_write(int degree, int range); 402
*/


int main(int argc, char* argv[])
{
    int syscallNum;
    int returnVal;
    if (argc < 2)
    {
        printf("Enter syscall number and its arguments.\n");
        printf("Available syscalls - sys_set_gps_location 398.\n");
        return 1;
    }
    syscallNum = atoi(argv[1]);
    if (syscallNum == 398)
    {
        if (argc < 6)
        {
            printf("Not enough arguments! Enter lat_int, lat_frac, long_int, long_frac, accuracy.\n");
            return 1;
        }
        gps_location loc = 
        {
            .lat_integer = atoi(argv[2]),
            .lat_fractional = atoi(argv[3]),
            .lng_integer = atoi(argv[4]),
            .lng_fractional = atoi(argv[5]),
            .accuracy = atoi(argv[6])
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
    return 0;
}