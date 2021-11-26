#include <stdio.h>
#include <unistd.h>
#include <stdlib.h>
#include <stdint.h>
#include <string.h>    
#include <errno.h>
#include <sys/syscall.h>
#include <linux/types.h>
#include <linux/sched.h>
#include <bits/types/struct_sched_param.h>

void set_degree(int degree)
{
    syscall(398, degree);
}

void read_lock(int degree,int range)
{
    syscall(399, degree,range);
}

void write_lock(int degree,int range)
{
    syscall(400, degree,range);
}

void read_unlock(int degree,int range)
{
    syscall(401, degree,range);
}

void write_unlock(int degree,int range)
{
    syscall(402, degree,range);
}

int main(int argc, char* argv[])
{
    while(1)
    {
        sleep(2);
        set_degree(10);
        sleep(2);
        set_degree(11);
    }

    return 0;
}