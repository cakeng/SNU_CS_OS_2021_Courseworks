#ifndef _ROTATION_H
#define _ROTATION_H

#include <linux/types.h>
#include <linux/sched.h>
#include <linux/list.h>
#include <linux/errno.h>
#include <linux/syscalls.h>
#include <linux/mutex.h>
#include <linux/slab.h>

#define __DEBUG_ROTLOCK 1
#define __ROT_RANGE 24

typedef enum ROT_STATE
{
    ROT_GRABBED, ROT_WRITE_WAIT, ROT_READ_WAIT, ROT_WAIT_RELEASED, ROT_GRAB_RELEASED
} ROT_STATE;

extern int current_rotation;

typedef struct 
{
    ROT_STATE state;
    int writelock;
    int degree;
    int range;
    struct task_struct* task;
    struct list_head node[__ROT_RANGE];
} rotlock_node;

extern rotlock_node locks;
extern rotlock_node read_lock_lists;
extern rotlock_node write_lock_lists;

void exit_rotlock(struct task_struct *tsk);

#endif //_ROTATION_H