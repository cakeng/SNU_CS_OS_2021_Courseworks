#ifndef _ROTATION_H
#define _ROTATION_H

#include <linux/types.h>
#include <linux/sched.h>
#include <linux/list.h>
#include <linux/errno.h>
#include <linux/syscalls.h>
#include <linux/mutex.h>

#define __DEBUG_ROTLOCK 1
#define __ROT_RANGE 360

extern int current_rotation;

typedef struct 
{
    int degree;
    int range;
    int lock_held;
    int lock_arr[__ROT_RANGE];
    pid_t tid;
    struct task_struct* task;
    struct list_head node;
} rotlock_node;

extern pid_t locks [__ROT_RANGE];
extern rotlock_node read_lock_lists [__ROT_RANGE];
extern rotlock_node write_lock_lists [__ROT_RANGE];

#endif //_ROTATION_H