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

#define __LOOP_SEC 30000000ULL 

int main(int argc, char* argv[])
{
    uint64_t freq = 20;
    int silent = 0;
    int startAsWRR = 1;
    int forkNum = 0;
    uint64_t i = 0;
    int childPid;
    int weight = 0;
    if (argc > 1)
    {
        silent = (int)atoi(argv[1]);
    }
    if (argc > 2)
    {
        forkNum = (int)atoi(argv[2]);
    }
    if (argc > 3)
    {
        weight = (uint64_t)atoi(argv[3]);
    }
    if (argc > 4)
    {
        freq = (uint64_t)atoi(argv[4]);
    }
    if (argc > 5)
    {
        startAsWRR = (uint64_t)atoi(argv[5]);
    }
    if (startAsWRR)
    {
        struct sched_param userparam = { .sched_priority = 0 };
        syscall(156, NULL, 7, &userparam);
    }
    
	struct timeval startTime, endTime;
    double diffTime;
    if(weight > 0)
    {
        syscall(398, NULL, weight);
    }
    gettimeofday(&startTime, NULL);
    i = 0;
    while (1)
    {
        i++;
        if (i >= __LOOP_SEC*freq)
        {
            i = 0;
            gettimeofday(&endTime, NULL);
            diffTime = ( endTime.tv_sec - startTime.tv_sec ) + ((double)( endTime.tv_usec - startTime.tv_usec ) / 1000000);
            if (!silent)
            {
                printf("Infloop PID %d - %.4lf seconds have passed.\n", (int)getpid(), diffTime);
            }
            gettimeofday(&startTime, NULL);
            if (forkNum)
            {
                for (i = 0; i < forkNum; i++)
                {
                    childPid = (int)fork();
                    if (childPid)
                    {
                        printf ("Infloop fork %lld, child process PID %d.\n", i, childPid);
                    }
                    else
                    {
                        break;
                    }
                }
                forkNum = 0;
            }
        }
    }
}