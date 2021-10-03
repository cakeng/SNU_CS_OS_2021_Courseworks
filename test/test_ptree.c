#include <stdio.h>
#include <unistd.h>
#include <stdlib.h>
#include <sys/syscall.h>
#include <linux/types.h>
#include "prinfo.h"
#include <errno.h>
#define BUFFER_SIZE 4096

void error_checker(int nr){

    if(errno == EINVAL)
    {
        printf("EINVAL_error_occured!");
    }
    if(errno == EFAULT)
    {
        printf("Efault_error_occured!");
    }

}

#define push(sp_tap, n) (*((sp_tap)++) = (n))
#define pop(sp_tap) (*--(sp_tap))

void tree_printer(int num, struct prinfo* buf){
    int num_of_tap = 0;
    int num_of_stack = 0;

    int stack_sibling_num_of_tap[1000];
    int *sp_tap;
    int update = 0;
    sp_tap = stack_sibling_num_of_tap;
    //printf("%d \n",sp_tap);
    int cnt = 0;
    for (int i = 0; i < num; i++)
    {
        struct prinfo* prPtr = buf + i;

        if(i != 0){
            if(prPtr ->parent_pid == (prPtr - 1) ->pid) //if parent layer + 1
            {
                num_of_tap ++;
            }

            else if(update != 0)
            {
                num_of_tap = update;
            }

            if(sp_tap != stack_sibling_num_of_tap && prPtr ->first_child_pid == 0 )                 //if stack not empty & has no 1st child => next=>sibling stack
            {
                if(prPtr -> next_sibling_pid != 0)
                {
                    push(sp_tap, num_of_tap);
                }
                int x_tap = pop(sp_tap);
                update = x_tap;
            }
            
            if(prPtr -> next_sibling_pid != 0) //if next sibling exist => stack
            {
                if (update != 0)
                {
                    update = 0;
                }
                else
                {
                    push(sp_tap, num_of_tap);
                }
            }

        }
        for (int k = 0; k<num_of_tap; k ++)
        {
            printf("\t");
        }
        printf("Entry %d: %s,%d,%lld,%d,%d,%d,%lld\n", i, prPtr->comm, prPtr->pid, prPtr->state,
  prPtr->parent_pid, prPtr->first_child_pid, prPtr->next_sibling_pid, prPtr->uid);
    }
    //printf("%d \n",sp_tap);
}


int main()
{
    int num = BUFFER_SIZE;
    int* nr = &num;
    int returnVal;
    printf ("Calling syscall 398...\n");
    struct prinfo* buf = malloc(sizeof(struct prinfo)*BUFFER_SIZE);
    returnVal = syscall(398, NULL, nr);
    printf ("Called syscall 398. Terminating.\n");
    tree_printer(num,buf);
    error_checker(1);

    free(buf);
        return 0;
}


