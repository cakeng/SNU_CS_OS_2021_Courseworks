#include "rotation.h"

int current_rotation = 0;
pid_t locks [__ROT_RANGE];
rotlock_node read_lock_lists[__ROT_RANGE];
rotlock_node write_lock_lists[__ROT_RANGE];
DEFINE_MUTEX(rotlock_mutex);

int initiliazed = 0;

void init(void)
{
    int i;
    mutex_lock(&rotlock_mutex);
    if (initiliazed == 0)
    {
        for (i = 0; i < __ROT_RANGE; i++)
        {
            locks[i] = -1;
            read_lock_lists[i].degree = -1;
            read_lock_lists[i].range = -1;
            read_lock_lists[i].lock_held = -1;
            read_lock_lists[i].tid = 0;
            read_lock_lists[i].task = NULL;
            INIT_LIST_HEAD(&read_lock_lists[i].node);
            INIT_LIST_HEAD(&write_lock_lists[i].node);
        }
        initiliazed = 1;
    }
    mutex_unlock(&rotlock_mutex);
}

int check_degree (int degree)
{
    if (0 <= degree && degree < 360)
    {
        return 1;
    }
    return 0;
}

int check_range (int range)
{
    if (0 < range && range < 180)
    {
        return 1;
    }
    return 0;
}

int check_rot (int degree, int range)
{
    return check_degree(degree) && check_range (range);
}

int get_lower_bound_DR (int degree, int range)
{
    return (degree + __ROT_RANGE - range) % __ROT_RANGE;
}
int get_upper_bound_DR (int degree, int range)
{
    return (degree + __ROT_RANGE + range) % __ROT_RANGE;
}
int get_lower_bound_NODE (rotlock_node* node)
{
    return (node->degree + __ROT_RANGE - node->range) % __ROT_RANGE;
}
int get_upper_bound_NODE (rotlock_node* node)
{
    return (node->degree + __ROT_RANGE + node->range) % __ROT_RANGE;
}

void set_node_DR(rotlock_node* node, int degree, int range)
{
    int i;
    int degree_normalized = degree % __ROT_RANGE;
    int upper_bound = get_upper_bound_DR (degree, range);
    int lower_bound = get_lower_bound_DR (degree, range);
    for (i = 0; i < __ROT_RANGE; i++)
    {
        if (lower_bound <= i && i <= upper_bound)
        {

        }
    }
}


long do_set_rotation(int degree)
{
    long return_val = 0;
    #if __DEBUG_ROTLOCK
    printk("RTL DEBUG: set_rotation called. degree - %d\n", degree);
    #endif
    init();
	if(check_degree (degree) == 0)
    {
        #if __DEBUG_ROTLOCK
        printk("RTL DEBUG: set_rotation received wrong degree input value.\n");
        #endif
        return -EINVAL;
    }
		
	mutex_lock(&rotlock_mutex);
	current_rotation = degree;
	mutex_unlock(&rotlock_mutex);

    #if __DEBUG_ROTLOCK
    printk("RTL DEBUG: Rotation set to %d\n",current_rotation);
    #endif
	return return_val;
}

long do_rotlock_read (int degree, int range)
{
    long return_val = 0;
    #if __DEBUG_ROTLOCK
    printk("RTL DEBUG: do_rotlock_read called. - degree %d, range %d.\n", degree, range);
    #endif
    init();
    if(check_rot (degree, range) == 0)
    {
        #if __DEBUG_ROTLOCK
        printk("RTL DEBUG: do_rotlock_read received wrong input values.\n");
        #endif
        return -EINVAL;
    }
    return return_val;
}
long do_rotlock_write (int degree, int range)
{
    long return_val = 0;
    #if __DEBUG_ROTLOCK
    printk("RTL DEBUG: do_rotlock_write called. - degree %d, range %d.\n", degree, range);
    #endif
    init();
    if(check_rot (degree, range) == 0)
    {
        #if __DEBUG_ROTLOCK
        printk("RTL DEBUG: do_rotlock_write received wrong input values.\n");
        #endif
        return -EINVAL;
    }
    return return_val;
}
long do_rotunlock_read (int degree, int range)
{
    long return_val = 0;
    #if __DEBUG_ROTLOCK
    printk("RTL DEBUG: do_rotunlock_read called. - degree %d, range %d.\n", degree, range);
    #endif
    init();
    if(check_rot (degree, range) == 0)
    {
        #if __DEBUG_ROTLOCK
        printk("RTL DEBUG: do_rotunlock_read received wrong input values.\n");
        #endif
        return -EINVAL;
    }
    return return_val;
}
long do_rotunlock_write (int degree, int range)
{
    long return_val = 0;
    #if __DEBUG_ROTLOCK
    printk("RTL DEBUG: do_rotunlock_write called. - degree %d, range %d.\n", degree, range);
    #endif
    init();
    if(check_rot (degree, range) == 0)
    {
        #if __DEBUG_ROTLOCK
        printk("RTL DEBUG: do_rotunlock_write received wrong input values.\n");
        #endif
        return -EINVAL;
    }
    return return_val;
}


SYSCALL_DEFINE1(set_rotation, int, degree)
{
	return do_set_rotation(degree);
}

SYSCALL_DEFINE2(rotlock_read, int, degree, int, range)
{
	return do_rotlock_read(degree, range);
}

SYSCALL_DEFINE2(rotlock_write, int, degree, int, range)
{
	return do_rotlock_write(degree, range);
}

SYSCALL_DEFINE2(rotunlock_read, int, degree, int, range)
{
	return do_rotunlock_read(degree, range);
}

SYSCALL_DEFINE2(rotunlock_write, int, degree, int, range)
{
	return do_rotunlock_write(degree, range);
}