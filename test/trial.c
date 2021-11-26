#include <stdio.h>
#include <unistd.h>
#include <stdlib.h>
#include <stdint.h>
#include <string.h>    
#include <math.h>
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
    if(argc == 2)
    {
        char pcnum[20];
        int startNum = atoi(argv[1]);
        sprintf(pcnum, "%d", startNum);
        int counter = 0;
        while(1)
        {
             
            read_lock(90,90);
            sleep(1);
            char text[100];
            FILE* fp = fopen("integer","r");
            fgets(text, sizeof(text), fp);
            //char *ptr = strtok(text, " ");
            
            //for (int i = 0; i < counter - 1; ++i)            
            //{
                
            //    ptr = strtok(NULL, " ");     
            //}
            //counter += 1;
            //if(ptr == NULL)
            //{
            //    break;
            //}
            fclose(fp);
            printf("trial - %d : %d = ",startNum, atoi(text));
            primeFactors(atoi(text));
            read_unlock(90,90);

        }
    }
    else
    {
        printf("error\n");
        
    }

    return 0;
}