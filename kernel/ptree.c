#include <linux/syscalls.h>
#include <linux/prinfo.h>
#include <linux/sched.h>
#include <linux/cred.h>
#include <linux/uidgid.h>
#include <linux/list.h>

#define __DEBUG_PTREE 1

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
void prinfoCopy(struct prinfo* out, struct task_struct* task)
{
	#ifdef __DEBUG_PTREE
	printk("PTREE - prinfoCopy: Copying to location %lld", (uint64_t)out);
	printk("PTREE - prinfoCopy: state:  %ld\n", task->state);
	printk("PTREE - prinfoCopy: pid:  %d\n", task->pid);
	printk("PTREE - prinfoCopy: parent_pid: %d\n", task->real_parent->pid);
	printk("PTREE - prinfoCopy: first_child_pid:  %d\n", getChild(task));
	printk("PTREE - prinfoCopy: next_sibling_pid:  %d\n", getSibling(task));
	printk("PTREE - prinfoCopy: uid:  %lld\n", (int64_t)(task_uid(task).val));
	printk("PTREE - prinfoCopy: comm:  %s\n", task->comm);
	#endif

	out->state = task->state;
    out->pid = task->pid;
    out->parent_pid = task->real_parent->pid;
    out->first_child_pid = getChild(task);
    out->next_sibling_pid = getSibling(task);
    out->uid = (int64_t)(task_uid(task).val);
    strncpy(out->comm, task->comm, TASK_COMM_LEN);
}

int ptree(struct prinfo *buf, int *nr)
{
	int i;
	int bufferSize = *nr;
	int processNum = 0;
	int copiedNum = 0;
	printk("PTREE - Ptree Called!\n");
	read_lock(&tasklist_lock);
	for (i = 1; i < 10; i++)
	{
		#ifdef __DEBUG_PTREE
			printk("PTREE - Processing pid %d\n", i);
		#endif
		prinfoCopy (buf + i, find_task_by_vpid(i));
		processNum++;
	}
	
	read_unlock(&tasklist_lock);

	*nr = processNum;
	return copiedNum;
}

SYSCALL_DEFINE2(ptree, struct prinfo*, buf, int*, nr)
{
	return ptree(buf, nr);
}