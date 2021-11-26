#include <stdio.h>
#include <unistd.h>
#include <stdlib.h>
#include <stdint.h>
#include <sys/time.h>
#include <errno.h>
#include <sys/syscall.h>
#include <linux/types.h>
#include <linux/sched.h>
#include <bits/types/struct_sched_param.h>

int main(int argc, char* argv[])
{
    int hold_secs = 5;
    int silent = 0;
    int degree, range, returnVal;
    int write_lock;
    if (argc < 4)
    {
        printf ("Please input the initial lock degree and range.\n");
        printf ("Argument list: R(0)/W(1) degree range (hold_secs silent - Optional)\n");
        return 0;
    }
    write_lock = (int)atoi(argv[1]);
    degree = (int)atoi(argv[2]);
    range = (int)atoi(argv[3]);
    if (argc > 4)
    {
        hold_secs = atoi(argv[4]);
    }
    if (argc > 5)
    {
        silent = atoi(argv[5]);
    }

	struct timeval startTime, endTime;
    int diffTime = 0, oldDiff = 0;
    if (!silent)
    {
        printf("Lock Grabber %d - write %d, degree %d, range %d, Requesting lock.\n", (int)getpid(), write_lock, degree, range);
    }
    if (write_lock == 0)
    {
        returnVal = syscall(399, degree, range);
    }
    else
    {
        returnVal = syscall(400, degree, range);
    }
    if (errno == EINVAL)
    {
        printf("Lock Grabber %d - EINVAL received. Not a valid parameter.\n", (int)getpid());
        return 0;
    }
    gettimeofday(&startTime, NULL);
    while (diffTime < hold_secs)
    {
        gettimeofday(&endTime, NULL);
        diffTime = ( endTime.tv_sec - startTime.tv_sec );
        if (!silent && diffTime > oldDiff)
        {
            printf("Lock Grabber %d - write %d, degree %d, range %d, %d seconds have passed.\n", (int)getpid(), write_lock, degree, range, diffTime);
            oldDiff = diffTime;
        }
    }
    if (!silent)
    {
        printf("Lock Grabber %d - write %d, degree %d, range %d, Releasing lock.\n", (int)getpid(), write_lock, degree, range);
    }
    if (write_lock == 0)
    {
        returnVal = syscall(401, degree, range);
    }
    else
    {
        returnVal = syscall(402, degree, range);
    }
    if (errno == EINVAL)
    {
        printf("Lock Grabber %d - EINVAL received. Not a valid parameter.\n", (int)getpid());
        return 0;
    }
} 