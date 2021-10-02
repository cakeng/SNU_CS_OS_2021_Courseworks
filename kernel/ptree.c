#include <linux/syscalls.h>
#include <linux/prinfo.h>
#include <linux/sched.h>
#include <linux/list.h>

pid_t getChild(struct task_struct* task)
{
	struct list_head* childList = &(task->children);
	if (list_empty(childList))
	{
		return 0;
	}
	else
	{
		return list_first_entry(childList, struct task_struct, sibling)->pid;
	}
}
pid_t getSibling(struct task_struct* task)
{
	return list_first_entry(&(task->sibling), struct task_struct, sibling)->pid;
}


int ptree(struct prinfo *buf, int *nr)
{
	printk("Ptree Called!\n");
	read_lock(&tasklist_lock);
	struct task_struct *pid0 = find_task_by_vpid(0);

	read_unlock(&tasklist_lock);
	return 0;
}

SYSCALL_DEFINE2(ptree, struct prinfo*, buf, int*, nr)
{
	return ptree(buf, nr);
}