#include <stdio.h>
#include <unistd.h>
#include <stdlib.h>
#include <stdint.h>
#include <errno.h>
#include <sys/syscall.h>
#include <linux/types.h>
#include <linux/sched.h>
#include <bits/types/struct_sched_param.h>

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
        printf("Available syscalls - sys_set_rotation 398, sys_rotlock_read 399, sys_rotlock_write 400, sys_rotunlock_read 401, sys_rotunlock_write 402.\n");
        return 1;
    }
    syscallNum = atoi(argv[1]);
    if (syscallNum == 398)
    {
        if (argc < 3)
        {
            printf("Not enough arguments!\n");
            return 1;
        }
        int degree = atoi(argv[2]);
        printf("Calling syscall sys_set_rotation, degree %d.\n", degree);
        returnVal = syscall(398, degree);
        printf("Syscall sys_set_rotation returned - %d.\n", returnVal);
    }
    else if (syscallNum == 399)
    {
        if (argc < 4)
        {
            printf("Not enough arguments!\n");
            return 1;
        }
        int degree = atoi(argv[2]);
        int range = atoi(argv[3]);
        printf("Calling syscall sys_rotlock_readr, degree %d, range %d.\n", degree, range);
        returnVal = syscall(399, degree, range);
        printf("Syscall sys_rotlock_read returned - %d.\n", returnVal);
    }
    else if (syscallNum == 400)
    {
        if (argc < 4)
        {
            printf("Not enough arguments!\n");
            return 1;
        }
        int degree = atoi(argv[2]);
        int range = atoi(argv[3]);
        printf("Calling syscall sys_rotlock_write, degree %d, range %d.\n", degree, range);
        returnVal = syscall(400, degree, range);
        printf("Syscall sys_rotlock_write returned - %d.\n", returnVal);
    }
    else if (syscallNum == 401)
    {
        if (argc < 4)
        {
            printf("Not enough arguments!\n");
            return 1;
        }
        int degree = atoi(argv[2]);
        int range = atoi(argv[3]);
        printf("Calling syscall sys_rotunlock_read, degree %d, range %d.\n", degree, range);
        returnVal = syscall(401, degree, range);
        printf("Syscall sys_rotunlock_read returned - %d.\n", returnVal);
    }
    else if (syscallNum == 402)
    {
        if (argc < 4)
        {
            printf("Not enough arguments!\n");
            return 1;
        }
        int degree = atoi(argv[2]);
        int range = atoi(argv[3]);
        printf("Calling syscall sys_rotunlock_write, degree %d, range %d.\n", degree, range);
        returnVal = syscall(402, degree, range);
        printf("Syscall sys_rotunlock_write returned - %d.\n", returnVal);
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