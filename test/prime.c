
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
#include <math.h>

void primeFactors(int n)
{
    for (int i = 2; i <= sqrt(n); i = i+1)
    {
        while (n%i == 0)
        {
            printf("%d ", i);
            n = n/i;
        }
    }
 
    if (n > 2)
    {
        printf ("%d \n", n);
    }
}
 
int main(int argc, char* argv[])
{
    struct timeval startTime, endTime;
    double diffTime;
    
    uint64_t n = atoll(argv[1]);

    struct sched_param userparam = { .sched_priority = 0 };
    syscall(156, NULL, 7, &userparam);
    //printf("weithg set to %d \n",argv[2]);
    syscall(398, NULL, atoi(argv[2]));

    gettimeofday(&startTime, NULL);
    for (uint64_t i = 0; i <= 50; i = i+1)
    {
        primeFactors(n + i);
    }
    gettimeofday(&endTime, NULL);


    diffTime = ( endTime.tv_sec - startTime.tv_sec ) + ((double)( endTime.tv_usec - startTime.tv_usec ) / 1000000);
    printf("prime_factorization PID %d - %.4lf seconds have passed.\n", (int)getpid(), diffTime);


    return 0;
}