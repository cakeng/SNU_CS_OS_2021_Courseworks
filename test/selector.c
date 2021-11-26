#include <stdio.h>
#include <unistd.h>
#include <stdlib.h>
#include <stdint.h>
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
    if(argc == 2)
    {
        write_lock(5,5);
        int startNum = atoi(argv[1]);
        FILE* fp1 = fopen("integer","w");
        fclose(fp1);
        write_unlock(5,5);
        while(1)
        {
             
            write_lock(5,5);
            sleep(0.3);
            char text[20];
            sprintf(text, "%d", startNum);
            FILE* fp = fopen("integer","a");
            fputs(text,fp);
            fputs(" ",fp);
            fclose(fp);
            printf("selector: %d.\n", startNum);
            startNum += 1;
            
            write_unlock(5,5);

        }
    }
    else
    {
        printf("error\n");
        
    }

    return 0;
}