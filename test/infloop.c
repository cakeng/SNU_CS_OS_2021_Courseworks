#include <stdio.h>
#include <unistd.h>
#include <stdlib.h>
#include <stdint.h>
#include <sys/time.h>

#define __LOOP_SEC 40909090ULL // ~1 second

int main(int argc, char* argv[])
{
    uint64_t freq = 30;
    if (argc > 1)
    {
        freq = (uint64_t)atoi(argv[1]);
    }
    uint64_t i = 0;
	struct timeval startTime, endTime;
    uint64_t diffTime;
    gettimeofday(&startTime, NULL);
    while (1)
    {
        i++;
        if (i >= __LOOP_SEC*freq)
        {
            i = 0;
            gettimeofday(&endTime, NULL);
            diffTime = (endTime.tv_sec - startTime.tv_sec);
            printf("Infloop PID %d - %lld seconds have passed.\n", (int)getpid(), diffTime);
        }
    }
}