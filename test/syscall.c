#include <stdio.h>
#include <unistd.h>
#include <stdlib.h>
#include <stdint.h>
#include <errno.h>
#include <sys/syscall.h>
#include <linux/types.h>
#include <linux/sched.h>
#include <bits/types/struct_sched_param.h>

#define USER_sched_setparam 154
#define USER_sched_getparam 155
#define USER_sched_setscheduler 156
#define USER_sched_getscheduler 157
#define USER_sched_yield 158
#define USER_sched_get_priority_max 159
#define USER_sched_get_priority_min 160
#define USER_sched_rr_get_interval 161
#define USER_sched_setweight 398
#define USER_sched_getweight 399

/* Related Syscalls
asmlinkage long sys_USER_sched_setscheduler(pid_t pid, int policy, struct sched_param __user *param);
asmlinkage long sys_sched_setparam(pid_t pid, struct sched_param __user *param);
asmlinkage long sys_sched_setattr(pid_t pid, struct sched_attr __user *attr, unsigned int flags);
asmlinkage long sys_sched_getscheduler(pid_t pid);
asmlinkage long sys_sched_getparam(pid_t pid, struct sched_param __user *param);
asmlinkage long sys_sched_getattr(pid_t pid, struct sched_attr __user *attr, unsigned int size, unsigned int flags);
asmlinkage long sys_sched_setaffinity(pid_t pid, unsigned int len, unsigned long __user *user_mask_ptr);
asmlinkage long sys_sched_getaffinity(pid_t pid, unsigned int len, unsigned long __user *user_mask_ptr);
asmlinkage long sys_sched_setweight(pid_t pid, int weight);
asmlinkage long sys_sched_getweight(pid_t pid);
*/


int main(int argc, char* argv[])
{
    int syscallNum;
    int returnVal;
    if (argc < 2)
    {
        printf("Enter syscall number and its arguments.\n");
        printf("Available syscalls - sched_setscheduler 156, sched_getscheduler 157, sched_setweight 398, USER_sched_getweight 399.\n");
        return 1;
    }
    syscallNum = atoi(argv[1]);
    if (syscallNum == USER_sched_setscheduler)
    {
        if (argc < 4)
        {
            printf("Not enough arguments for sched_setscheduler... Number of arguments - %d\n", argc);
            return 1;
        }
        int pid = atoi(argv[2]);
        int policy = atoi(argv[3]);
        int priority = 0;
        if (argc > 4)
        {
            priority = atoi(argv[4]);
        }
        struct sched_param userparam = { .sched_priority = priority };
        printf("Calling syscall sched_setscheduler, pid - %d, policy - %d, priority - %d\n", pid, policy, priority);
        returnVal = syscall(USER_sched_setscheduler, (pid_t)pid, policy, &userparam);
        printf("Syscall sched_setscheduler returned - %d\n", returnVal);
    }
    else if (syscallNum == USER_sched_getscheduler)
    {
        if (argc < 3)
        {
            printf("Not enough arguments for sched_getscheduler... Number of arguments - %d\n", argc);
            return 1;
        }
        int pid = atoi(argv[2]);
        printf("Calling syscall sched_getscheduler, pid - %d\n", pid);
        returnVal = syscall(USER_sched_getscheduler, (pid_t)pid);
        printf("Syscall sched_getscheduler returned - %d\n", returnVal);
    }
    else if (syscallNum == USER_sched_setweight)
    {
        if (argc < 4)
        {
            printf("Not enough arguments for sched_setweight... Number of arguments - %d\n", argc);
            return 1;
        }
        int pid = atoi(argv[2]);
        int weight = atoi(argv[3]);
        printf("Calling syscall sched_setweight, pid - %d, weight - %d\n", pid, weight);
        returnVal = syscall(USER_sched_setweight, (pid_t)pid, weight);
        printf("Syscall sched_setweight returned - %d\n", returnVal);
    }
    else if (syscallNum == USER_sched_getweight)
    {
        if (argc < 3)
        {
            printf("Not enough arguments for sched_getweight... Number of arguments - %d\n", argc);
            return 1;
        }
        int pid = atoi(argv[2]);
        printf("Calling syscall sched_getweight, pid - %d\n", pid);
        returnVal = syscall(USER_sched_getweight, (pid_t)pid);
        printf("Syscall sched_getweight returned - %d\n", returnVal);
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
