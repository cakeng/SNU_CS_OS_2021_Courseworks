#include <linux/syscalls.h>
#include <linux/prinfo.h>
#include <linux/sched.h>
#include <linux/errno.h>
#include <linux/cred.h>
#include <linux/slab.h>
#include <linux/uidgid.h>
#include <linux/list.h>
#include <linux/uaccess.h>

#define __DEBUG_PTREE 1

pid_t getChildPid(struct task_struct* task)
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
	return 0;
}
pid_t getSiblingPid(struct task_struct* task)
{
	struct list_head* siblingList = &(task->sibling);
	if (list_is_last(siblingList, &(task->real_parent->children)))
	{
		return 0;
	}
	else
	{
		return list_first_entry(siblingList, struct task_struct, sibling)->pid;
	}
	return 0;
}
void prinfoCopy(struct prinfo* out, struct task_struct* task)
{
	#ifdef __DEBUG_PTREE
	printk("PTREE - prinfoCopy: Copying to location %lld", (uint64_t)out);
	printk("PTREE - prinfoCopy: state:  %ld\n", task->state);
	printk("PTREE - prinfoCopy: pid:  %d\n", task->pid);
	printk("PTREE - prinfoCopy: parent_pid: %d\n", task->real_parent->pid);
	printk("PTREE - prinfoCopy: first_child_pid:  %d\n", getChildPid(task));
	printk("PTREE - prinfoCopy: next_sibling_pid:  %d\n", getSiblingPid(task));
	printk("PTREE - prinfoCopy: uid:  %lld\n", (int64_t)(task_uid(task).val));
	printk("PTREE - prinfoCopy: comm:  %s\n", task->comm);
	#endif

	out->state = task->state;
    out->pid = task->pid;
    out->parent_pid = task->real_parent->pid;
    out->first_child_pid = getChildPid(task);
    out->next_sibling_pid = getSiblingPid(task);
    out->uid = (int64_t)(task_uid(task).val);
    strncpy(out->comm, task->comm, TASK_COMM_LEN);
}

struct prStack {
	int id;
	struct task_struct* next;
};
void dfsCopy (struct prinfo *buf, int bufferSize, int* copiedNumPtr, int* processNumPtr)
{
	int copiedNum = 0;
	int processNum = 0;
	struct task_struct* currentTask = &init_task;
	#ifdef __DEBUG_PTREE
	printk("PTREE - dfsCopy called! buffersize - %d, init task address - %lld\n", bufferSize, (uint64_t)currentTask);
	#endif
	while(1)
	{
		if (copiedNum < bufferSize)
		{
			prinfoCopy(buf + copiedNum, currentTask);
			copiedNum++;
			#ifdef __DEBUG_PTREE
			printk("PTREE - dfsCopy copying task... copiedNum after copying - %d\n", copiedNum);
			#endif
		}

		//Leaf node
		if (list_empty(&(currentTask->children)))
		{
			// If current task is the last entry of the parent's children list -> traverse to parent who has untraversed sibling.
			while (list_is_last(&(currentTask->sibling), &(currentTask->real_parent->children)))
			{
				currentTask = currentTask->real_parent;
				#ifdef __DEBUG_PTREE
				printk("PTREE - dfsCopy traversing up... current task address - %lld\n", (uint64_t)currentTask);
				#endif
			}
			if (currentTask == &init_task)
			{
				#ifdef __DEBUG_PTREE
				printk("PTREE - dfsCopy reached init task, exiting loop...\n");
				#endif
				break;
			}
			currentTask = list_first_entry(&(currentTask->sibling), struct task_struct, sibling);
			#ifdef __DEBUG_PTREE
			printk("PTREE - dfsCopy traversing horizontal... current task address - %lld\n", (uint64_t)currentTask);
			#endif
		}
		// If not leaf, traverse to the first child.
		else
		{
			currentTask = list_first_entry(&(currentTask->children), struct task_struct, sibling);
			#ifdef __DEBUG_PTREE
			printk("PTREE - dfsCopy traversing down... current task address - %lld\n", (uint64_t)currentTask);
			#endif
		}
		processNum++;
		#ifdef __DEBUG_PTREE
		printk("PTREE - dfsCopy incrementing traversed process num - current processNum - %d\n", processNum);
		#endif
	}
	*copiedNumPtr = copiedNum;
	*processNumPtr = processNum;
}

int ptree(struct prinfo *buf, int *nr)
{
	int bufferSize;
	int processNum;
	int copiedNum;
	struct prinfo* kernelBuf;

	#ifdef __DEBUG_PTREE
	printk("PTREE - Ptree Called!\n");
	#endif
	if (buf == NULL || nr == NULL)
	{
		printk("PTREE - ERROR! NULL operands! buf - %lld, nr - %lld\n", (uint64_t)buf, (uint64_t)nr);
		return -EINVAL;
	}
	#ifdef __DEBUG_PTREE
	printk("PTREE - Copying buffersize from nr...\n");
	#endif
	if(copy_from_user(&bufferSize, nr, sizeof(int))) 
	{
        printk("PTREE - ERROR! copy from nr unaccessible! nr - %lld\n", (uint64_t)nr);
        return -EFAULT;
    }
    if(bufferSize < 1) 
	{
        printk("PTREE - ERROR! buffersize less than 1! buffersize - %d\n", bufferSize);
        return -EINVAL;
    }
	#ifdef __DEBUG_PTREE
	printk("PTREE - Allocating buffer memory for kernel...\n");
	#endif
	kernelBuf = (struct prinfo*)kmalloc(sizeof(struct prinfo)*bufferSize, GFP_ATOMIC);


	read_lock(&tasklist_lock);
	#ifdef __DEBUG_PTREE
	printk("PTREE - Running dfsCopy... - buffersize - %d\n", bufferSize);
	#endif
	dfsCopy(kernelBuf, bufferSize, &copiedNum, &processNum);
	#ifdef __DEBUG_PTREE
	printk("PTREE - Returned from dfsCopy... - copiedNum - %d, processNum - %d\n", copiedNum, processNum);
	#endif
	read_unlock(&tasklist_lock);

	#ifdef __DEBUG_PTREE
	printk("PTREE - Copying copiedNum to nr...\n");
	#endif
	if(copy_to_user(nr, &copiedNum, sizeof(int)))
	{
        printk("PTREE - ERROR! write to nr unaccessible! nr - %lld\n", (uint64_t)nr);
        return -EFAULT;
    }
	#ifdef __DEBUG_PTREE
	printk("PTREE - Copying buffer to user buffer...\n");
	#endif
	if(copy_to_user(buf, kernelBuf, sizeof(struct prinfo)*copiedNum))
	{
        printk("PTREE - ERROR! write to user buf unaccessible! buf - %lld\n", (uint64_t)buf);
        return -EFAULT;
    }
	kfree(kernelBuf);

	#ifdef __DEBUG_PTREE
	printk("PTREE - Ptree Complete!\n");
	#endif
	return processNum;
}

SYSCALL_DEFINE2(ptree, struct prinfo*, buf, int*, nr)
{
	return ptree(buf, nr);
}