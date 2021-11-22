#include <linux/rotation.h>


int current_rotation = 0;
rotlock_node locks;
rotlock_node read_lock_lists;
rotlock_node write_lock_lists;
DEFINE_MUTEX(rotlock_mutex);

int initiliazed = 0;

void init(void)
{
    int i;
    mutex_lock(&rotlock_mutex);
    #if __DEBUG_ROTLOCK
    printk("RTL DEBUG: Initializing rotation lock...\n");
    #endif
    if (initiliazed == 0)
    {
        read_lock_lists.writelock = -1;
        read_lock_lists.state = -1;
        read_lock_lists.degree = -1;
        read_lock_lists.range = -1;
        read_lock_lists.task = NULL;
        write_lock_lists.writelock = -1;
        write_lock_lists.state = -1;
        write_lock_lists.degree = -1;
        write_lock_lists.range = -1;
        write_lock_lists.task = NULL;
        locks.writelock = -1;
        locks.state = -1;
        locks.degree = -1;
        locks.range = -1;
        locks.task = NULL;
        for (i = 0; i < __ROT_RANGE; i++)
        {
            INIT_LIST_HEAD(&locks.node[i]);
            INIT_LIST_HEAD(&read_lock_lists.node[i]);
            INIT_LIST_HEAD(&write_lock_lists.node[i]);
        }
        initiliazed = 1;
    }
    mutex_unlock(&rotlock_mutex);
}

int check_degree (int degree)
{
    if (0 <= degree && degree < __ROT_RANGE)
    {
        return 1;
    }
    return 0;
}

int check_range (int range)
{
    if (0 < range && range < (__ROT_RANGE/2))
    {
        return 1;
    }
    return 0;
}

int check_rot (int degree, int range)
{
    return check_degree(degree) && check_range (range);
}

int get_lower_bound (int degree, int range)
{
    return (degree + __ROT_RANGE - range) % __ROT_RANGE;
}
int get_upper_bound (int degree, int range)
{
    return (degree + __ROT_RANGE + range) % __ROT_RANGE;
}
int get_node_pid (rotlock_node* node)
{
    if (node == NULL)
    {
        #if __DEBUG_ROTLOCK
        printk("RTL DEBUG: ERROR!!! get_node_pid NULL parameter given!\n");
        #endif
        return -1;
    }
    return (int)task_pid_vnr(node->task);
}



/* Must be under Mutex protection! */
#define PRINT_RANGE 20;
void print_state(void)
{
    #if __DEBUG_ROTLOCK
    rotlock_node* targ_node;
    int i;
    printk("RTL DEBUG: Printing Rotation lock state. Current rotation: %d\n", current_rotation);
    for (i = 0; i < __ROT_RANGE; i++)
    {
        printk("RTL DEBUG:\tR%d\t", i);
        list_for_each_entry(targ_node, &(read_lock_lists.node[i]), node[i]) 
        {
            printk("%d,\t", get_node_pid(targ_node));
        }
        printk("\n");
        printk("RTL DEBUG:\tW%d\t", i);
        list_for_each_entry(targ_node, &(write_lock_lists.node[i]), node[i]) 
        {
            printk("%d,\t", get_node_pid(targ_node));
        }
        printk("\n");
        printk("RTL DEBUG:\tG%d\t", i);
        list_for_each_entry(targ_node, &(locks.node[i]), node[i]) 
        {
            printk("%d,\t", get_node_pid(targ_node));
        }
        printk("\n");
    }
    #endif
}

// Dequeues a node from the lists(queues) its contained in.
void dequeue_node(rotlock_node* node)
{
    int upper_bound, lower_bound, i;
    if (node == NULL)
    {
        #if __DEBUG_ROTLOCK
        printk("RTL DEBUG: ERROR!!! dequeue_node NULL parameter given!\n");
        #endif
        return;
    }
    if (!(node->state == ROT_WRITE_WAIT || node->state == ROT_READ_WAIT))
    {
        #if __DEBUG_ROTLOCK
        printk("RTL DEBUG: ERROR!!! dequeue_node parameter node does not belong to a list! Pid - %d, state %d\n", get_node_pid(node), node->state);
        #endif
        return;
    }
    upper_bound = get_upper_bound (node->degree, node->range);
    lower_bound = get_lower_bound (node->degree, node->range);
    for (i = lower_bound; i <= upper_bound; i++)
    {
        list_del(&node->node[i]);
    }
    node->state = ROT_WAIT_RELEASED;
    return;
}

// Checks if the given node can grab the wanted range of degrees.
int check_grabbable (rotlock_node* node)
{
    int upper_bound, lower_bound, i;
    rotlock_node* lock;
    if (node == NULL)
    {
        #if __DEBUG_ROTLOCK
        printk("RTL DEBUG: ERROR!!! check_grabbable NULL parameter given!\n");
        #endif
        return 0;
    }
    upper_bound = get_upper_bound (node->degree, node->range);
    lower_bound = get_lower_bound (node->degree, node->range);
    for (i = lower_bound; i <= upper_bound; i++)
    {
        lock = list_first_entry_or_null(&locks.node[i], rotlock_node, node[i]);
        if (lock != NULL)
        {
            // If either lock is a write lock, deny grabbing.
            if (lock->writelock == 1 || node->writelock == 1)
            {
                return 0;
            }
        }
    }
    return 1;
}

// Grabs all locks that a node needs.
void grab_range (rotlock_node* node)
{
    int upper_bound, lower_bound, i;
    if (node == NULL)
    {
        #if __DEBUG_ROTLOCK
        printk("RTL DEBUG: ERROR!!! grab_range NULL parameter given!\n");
        #endif
        return;
    }
    if (node->state != ROT_WAIT_RELEASED)
    {
        #if __DEBUG_ROTLOCK
        printk("RTL DEBUG: ERROR!!! grab_range parameter is not in wait released state! Pid - %d, state %d\n", get_node_pid(node), node->state);
        #endif
        return;
    }
    if (check_grabbable(node) == 0)
    {
        return;
    }
    upper_bound = get_upper_bound (node->degree, node->range);
    lower_bound = get_lower_bound (node->degree, node->range);
    for (i = lower_bound; i <= upper_bound; i++)
    {
        list_add_tail(&node->node[i], &(locks.node[i]));
    }
    node->state = ROT_GRABBED;
}

// Frees all locks that a node owns.
void free_range (rotlock_node* node)
{
    int upper_bound, lower_bound, i;
    if (node == NULL)
    {
        #if __DEBUG_ROTLOCK
        printk("RTL DEBUG: ERROR!!! free_range NULL parameter given!\n");
        #endif
        return;
    }
    if (node->state != ROT_GRABBED)
    {
        #if __DEBUG_ROTLOCK
        printk("RTL DEBUG: ERROR!!! free_range parameter node does not own a lock! Pid - %d, state %d\n", get_node_pid(node), node->state);
        #endif
        return;
    }
    upper_bound = get_upper_bound (node->degree, node->range);
    lower_bound = get_lower_bound (node->degree, node->range);
    for (i = lower_bound; i <= upper_bound; i++)
    {
        list_del(&node->node[i]);
    }
    node->state = ROT_GRAB_RELEASED;
}


void lock_engine(void)
{
    rotlock_node* write_list_entry, *read_list_entry;
    #if __DEBUG_ROTLOCK
    printk("RTL DEBUG: lock_engine called.\n");
    print_state();
    #endif
    // Try grabbing locks from the write lock list.
    list_for_each_entry(write_list_entry, &write_lock_lists.node[current_rotation], node[current_rotation])
    {
        if (write_list_entry != NULL)
        {
            if (check_grabbable (write_list_entry) != 0)
            {
                dequeue_node (write_list_entry);
                grab_range (write_list_entry);
                wake_up_process(write_list_entry->task);
                #if __DEBUG_ROTLOCK
                printk("RTL DEBUG: lock_engine woken up write lock PID %d.\n", get_node_pid(write_list_entry));
                print_state();
                #endif
                return;
            }
        }
    }
    // Grab all available locks from the read lock list.
    list_for_each_entry(read_list_entry, &read_lock_lists.node[current_rotation], node[current_rotation])
    {
        if (read_list_entry != NULL)
        {
            if (check_grabbable (read_list_entry) != 0)
            {
                dequeue_node (read_list_entry);
                grab_range (read_list_entry);
                wake_up_process(read_list_entry->task);
                #if __DEBUG_ROTLOCK
                printk("RTL DEBUG: lock_engine woken up read lock PID %d.\n", get_node_pid(read_list_entry));
                #endif
            }
        }
    }
    #if __DEBUG_ROTLOCK
    print_state();
    #endif
}
/* Must be under Mutex protection! */

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
    lock_engine();
	mutex_unlock(&rotlock_mutex);

    #if __DEBUG_ROTLOCK
    printk("RTL DEBUG: Rotation set to %d\n",current_rotation);
    #endif
	return return_val;
}

long do_rotlock_read (int degree, int range)
{
    rotlock_node* new_node;
    int upper_bound, lower_bound, i;
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

    new_node = (rotlock_node*) kmalloc(sizeof(rotlock_node), GFP_KERNEL);
    if (new_node == NULL)
    {
        #if __DEBUG_ROTLOCK
        printk("RTL DEBUG: do_rotlock_read unable to allocate kernel memory.\n");
        #endif
        return -EINVAL;
    }
    new_node->writelock = 0;
    new_node->state = ROT_READ_WAIT;
    new_node->degree = degree;
    new_node->range = range;
    new_node->task = current;

    upper_bound = get_upper_bound (degree, range);
    lower_bound = get_lower_bound (degree, range);

    mutex_lock(&rotlock_mutex);
    // Adding to the list.
    for (i = lower_bound; i <= upper_bound ; i++)
    {
        list_add_tail(&new_node->node[i], &(read_lock_lists.node[i]));
    }
    lock_engine();
    mutex_unlock(&rotlock_mutex);
    // Wait until grabbing lock.
    while(new_node->state != ROT_GRABBED) 
    {
        set_current_state(TASK_INTERRUPTIBLE);
        schedule();
    }
    __set_current_state(TASK_RUNNING);

    return 1;
}
long do_rotlock_write (int degree, int range)
{
    rotlock_node* new_node;
    int upper_bound, lower_bound, i;
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
    
    new_node = (rotlock_node*) kmalloc(sizeof(rotlock_node), GFP_KERNEL);
    if (new_node == NULL)
    {
        #if __DEBUG_ROTLOCK
        printk("RTL DEBUG: do_rotlock_read unable to allocate kernel memory.\n");
        #endif
        return -EINVAL;
    }
    new_node->writelock = 1;
    new_node->state = ROT_WRITE_WAIT;
    new_node->degree = degree;
    new_node->range = range;
    new_node->task = current;

    upper_bound = get_upper_bound (degree, range);
    lower_bound = get_lower_bound (degree, range);

    mutex_lock(&rotlock_mutex);
    // Adding to the list.
    for (i = lower_bound; i <= upper_bound ; i++)
    {
        list_add_tail(&new_node->node[i], &(read_lock_lists.node[i]));
    }
    lock_engine();
    mutex_unlock(&rotlock_mutex);
    // Wait until grabbing lock.
    while(new_node->state != ROT_GRABBED) 
    {
        set_current_state(TASK_INTERRUPTIBLE);
        schedule();
    }
    __set_current_state(TASK_RUNNING);

    return 1;
}

long do_rotunlock_read (int degree, int range)
{
    rotlock_node* targ_node;
    pid_t pid;
    int i;
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
    pid = task_pid_vnr(current);
    mutex_lock(&rotlock_mutex);
    for (i = 0; i < __ROT_RANGE; i++)
    {
        list_for_each_entry(targ_node, &(locks.node[i]), node[i]) 
        {
            if(get_node_pid(targ_node) == pid && targ_node->degree == degree && targ_node->range == range)
            {
                goto RR_EXIT;
            }
        }
        list_for_each_entry(targ_node, &(read_lock_lists.node[i]), node[i]) 
        {
            if(get_node_pid(targ_node) == pid && targ_node->degree == degree && targ_node->range == range)
            {
                goto RR_EXIT;
            }
	    }
        #if __DEBUG_ROTLOCK
        printk("RTL DEBUG: ERROR !! do_rotunlock_read no locks found!. PID %d, degree %d, range %d.\n", pid, degree, range);
        #endif
        return 0;
    }
    RR_EXIT:
    if (targ_node->state == ROT_READ_WAIT)
    {
        dequeue_node (targ_node);
    }
    else if (targ_node->state == ROT_GRABBED)
    {
        free_range (targ_node);
    }
    else
    {
        #if __DEBUG_ROTLOCK
        printk("RTL DEBUG: ERROR !! Releasing read lock in a wrong state!. PID %d, state %d.\n", get_node_pid(targ_node), targ_node->state);
        #endif
    }
    lock_engine();
    mutex_unlock(&rotlock_mutex);
    kfree (targ_node);

    return 1;
}

long do_rotunlock_write (int degree, int range)
{
    rotlock_node* targ_node;
    pid_t pid;
    int i;
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
    pid = task_pid_vnr(current);
    mutex_lock(&rotlock_mutex);
    for (i = 0; i < __ROT_RANGE; i++)
    {
        list_for_each_entry(targ_node, &(locks.node[i]), node[i]) 
        {
            if(get_node_pid(targ_node) == pid && targ_node->degree == degree && targ_node->range == range)
            {
                goto RW_EXIT;
            }
        }
        list_for_each_entry(targ_node, &(write_lock_lists.node[i]), node[i]) 
        {
            if(get_node_pid(targ_node) == pid && targ_node->degree == degree && targ_node->range == range)
            {
                goto RW_EXIT;
            }
	    }
        #if __DEBUG_ROTLOCK
        printk("RTL DEBUG: ERROR !! do_rotunlock_write no locks found!. PID %d, degree %d, range %d.\n", pid, degree, range);
        #endif
        return 0;
    }
    RW_EXIT:
    if (targ_node->state == ROT_WRITE_WAIT)
    {
        dequeue_node (targ_node);
    }
    else if (targ_node->state == ROT_GRABBED)
    {
        free_range (targ_node);
    }
    else
    {
        #if __DEBUG_ROTLOCK
        printk("RTL DEBUG: ERROR !! Releasing write lock in a wrong state!. PID %d, state %d.\n", get_node_pid(targ_node), targ_node->state);
        #endif
    }
    lock_engine();
    mutex_unlock(&rotlock_mutex);
    kfree (targ_node);

    return 1;
}

void exit_rotlock(struct task_struct *tsk)
{
    rotlock_node* targ_node, *tmp;
    int i;
    mutex_lock(&rotlock_mutex);
    for (i = 0; i < __ROT_RANGE; i++)
    {
        list_for_each_entry_safe(targ_node, tmp, &(read_lock_lists.node[i]), node[i])
        {
            if(targ_node->task == tsk)
            {
                if (targ_node->state == ROT_READ_WAIT)
                {
                    dequeue_node (targ_node);
                }
                else
                {
                    #if __DEBUG_ROTLOCK
                    printk("RTL DEBUG: ERROR !! exit_rotlock Releasing locks in a wrong state!. PID %d, state %d.\n", task_pid_vnr(current), targ_node->state);
                    #endif
                }
                kfree (targ_node);
            }
	    }
        list_for_each_entry_safe(targ_node, tmp, &(write_lock_lists.node[i]), node[i]) 
        {
            if(targ_node->task == tsk)
            {
                if (targ_node->state == ROT_WRITE_WAIT)
                {
                    dequeue_node (targ_node);
                }
                else
                {
                    #if __DEBUG_ROTLOCK
                    printk("RTL DEBUG: ERROR !! exit_rotlock Releasing locks in a wrong state!. PID %d, state %d.\n", task_pid_vnr(current), targ_node->state);
                    #endif
                }
                kfree (targ_node);
            }
	    }
        list_for_each_entry_safe(targ_node, tmp, &(locks.node[i]), node[i]) 
        {
            if(targ_node->task == tsk)
            {
                if (targ_node->state == ROT_GRABBED)
                {
                    free_range (targ_node);
                }
                else
                {
                    #if __DEBUG_ROTLOCK
                    printk("RTL DEBUG: ERROR !! exit_rotlock Releasing locks in a wrong state!. PID %d, state %d.\n", task_pid_vnr(current), targ_node->state);
                    #endif
                }
                kfree (targ_node);
            }
	    }
    }
    lock_engine();
    mutex_unlock(&rotlock_mutex);
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