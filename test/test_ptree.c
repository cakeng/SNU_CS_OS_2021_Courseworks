#include <stdio.h>
#include <unistd.h>
#include <stdlib.h>
#include <sys/syscall.h>
#include <linux/types.h>
#include "prinfo.h"

#define BUFFER_SIZE 4096

int main()
{
    int num = BUFFER_SIZE;
    int* nr = &num;
    int returnVal;
    printf ("Calling syscall 398...\n");
    struct prinfo* buf = malloc(sizeof(struct prinfo)*BUFFER_SIZE);
	returnVal = syscall(398, buf, nr);
    printf ("Called syscall 398. Terminating.\n");

    for (int i = 0; i < num; i++)
    {
        struct prinfo* prPtr = buf + i;
        printf("Entry %d: %s,%d,%lld,%d,%d,%d,%lld\n", i, prPtr->comm, prPtr->pid, prPtr->state,
  prPtr->parent_pid, prPtr->first_child_pid, prPtr->next_sibling_pid, prPtr->uid);
    }

    free(buf);
	return 0;
}