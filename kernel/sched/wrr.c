#include "sched.h"
#include <linux/slab.h>
#include <linux/types.h>
#include <linux/smp.h>
#include <linux/list.h>

// First CPU with its online bit on is designated as the "Master" WRR CPU...
// It's WRR queue always remains empty (or idle) and handles all load balancing.
// Master CPU is dynamically determined every time getMasterCPU_wrr() is called,
// through the CPU mask, to compensate for CPU hotplugging.
int getMasterCPU_wrr(void)
{
	int i;
	int val = cpumask_first(cpu_active_mask);
	for_each_possible_cpu(i)
	{
		if (cpumask_test_cpu(i, cpu_active_mask))
		{
			val = i;
		}
	}
	return val;
}
// Checks if a given CPU can run a given task. 
int checkRunnableCPU(int CPUID, struct task_struct *p)
{
	return ((CPUID != getMasterCPU_wrr()) 
		&& (cpumask_test_cpu(CPUID, cpu_active_mask)) 
		&& (cpumask_test_cpu(CPUID, &p->cpus_allowed)));
}

void print_wrr_rq(struct wrr_rq *wrr_rq)
{
	#if __WRR_SCHED_DEBUG
	struct list_head* queueHead = &wrr_rq->queue_head;
	struct list_head* queuePtr = queueHead;
	struct sched_wrr_entity *wrr;
	struct rq *rq = cpu_rq(wrr_rq->CPUID);
	int loopI;
	int currPid = 0;

	if (rq->curr)
	{
		currPid = rq->curr->pid;
	}
	if (wrr_rq->CPUID == getMasterCPU_wrr())
	{
		printk("WRR CPUID %d - \tWRR (CPU %d) MASTER runque status: Currently running (pid): %d, total weight - %d, nr_running - %d. "
		,smp_processor_id(), wrr_rq->CPUID, currPid, wrr_rq->total_weight, wrr_rq->wrr_nr_running);
	}
	else
	{
		printk("WRR CPUID %d - \tWRR (CPU %d) runque status: Currently running (pid): %d, total weight - %d, nr_running - %d. "
		,smp_processor_id(), wrr_rq->CPUID, currPid, wrr_rq->total_weight, wrr_rq->wrr_nr_running);
	}
	if (!list_empty(queuePtr))
	{
		loopI = 0;
		list_for_each(queuePtr, queueHead)
		{
			loopI++;
			wrr = list_entry(queuePtr, struct sched_wrr_entity, queue_node);
			printk("WRR CPUID %d - \t\tWRR (CPU %d) runque %d th entry: PID - %d, weight - %d, time slice - %d.\n"
				,smp_processor_id(), wrr_rq->CPUID, loopI, wrr->pid, wrr->weight, wrr->time_slice);
		}
	}
	#endif 
}

void print_all_wrr_rq(void)
{
	int i;
	#if __WRR_SCHED_DEBUG
	printk("WRR CPUID %d - Printing all WRR runque status (Master - %d)\n",smp_processor_id() , getMasterCPU_wrr());
	for_each_possible_cpu(i)
	{
		struct rq *rq = cpu_rq(i);
		struct wrr_rq *wrr_rq = &rq->wrr;
		print_wrr_rq(wrr_rq);
	}
	#endif 
}

void load_balance_wrr(struct rq *rq)
{
	int i;
	int weight;
	int taskWeightMax = -1, weightMax = -1, weightMin = INT_MAX;
	struct rq *rq_master = cpu_rq(getMasterCPU_wrr());
	struct rq *rq_max = rq_master, *rq_min = rq_master;
	struct task_struct *task;
	struct task_struct *task_targ = NULL;
	struct sched_wrr_entity *task_wrr = NULL;
	struct list_head* queuePtr;
	unsigned long flags;

	// Find CPUs with min weight and max weight
	rcu_read_lock();
	for_each_possible_cpu(i)
	{
		struct rq *rq = cpu_rq(i);
		// Check if the target is not Master & if target cpu is ACTIVE. (For hotplugging)
		if ((i != getMasterCPU_wrr()) && (cpumask_test_cpu(i, cpu_active_mask)))
		{
			int total_weight = rq->wrr.total_weight;
			if(weightMax < total_weight)
			{
				rq_max = rq;
				weightMax = total_weight;
			}
			if(weightMin > total_weight)
			{
				rq_min = rq;
				weightMin = total_weight;
			}
		}
	}
	rcu_read_unlock();
	// If Master CPU has wrr workload, always move from Master CPU.
	if(rq_master->wrr.total_weight)
	{
		rq_max = rq_master;
	}
	// If there are only a single task on the max queue, or if min queue is Master, return.
	if((rq_max != rq_master && rq_max->wrr.wrr_nr_running < 2) || rq_min == rq_master)
	{
		return;
	}
	// If min/max queues are the same, return.
	if(rq_min == rq_max)
	{
		return;
	}
	#if __WRR_SCHED_DEBUG
	// printk("WRR CPUID %d - load_balance selected min CPU %d, max CPU %d.\n",smp_processor_id(), cpu_of(rq_min), cpu_of(rq_max));
	#endif 

	local_irq_save(flags);
	double_rq_lock(rq_max, rq_min);
	// Select the first task to satisfy constraints.
	list_for_each(queuePtr, &rq_max->wrr.queue_head)
	{
		task_wrr = list_entry(queuePtr, struct sched_wrr_entity, queue_node);
		task = container_of(task_wrr, struct task_struct, wrr);
		weight = task_wrr->weight;
		// Check if valid task for migration.
		if ((task != rq_max->curr) && checkRunnableCPU(cpu_of(rq_min), task))
		{
			// Check if task is the max availabe in the rq_max's wrr queue.
			if (weight > taskWeightMax)
			{
				// Migrate only if the weight balance is not bronken (Except when moving from Master.)
				if (rq_max == rq_master || weightMax - weight > weightMin + weight)
				{
					task_targ = task;
					taskWeightMax = weight;
				}
			}
		}
	}
	// Move the selected task.
	if (task_targ != NULL)
	{
		deactivate_task(rq_max, task_targ, 0);
		set_task_cpu(task_targ, cpu_of(rq_min));
		activate_task(rq_min, task_targ, 0);
	}
	double_rq_unlock(rq_max, rq_min);
	local_irq_restore(flags);
	#if __WRR_SCHED_DEBUG
	if (task_targ != NULL)
	{	
		printk("WRR CPUID %d - load_balance moved task %d from CPU %d to CPU %d.\n"
			,smp_processor_id(), (int)task_targ->pid, cpu_of(rq_max), cpu_of(rq_min));
		print_all_wrr_rq();
	}
	else
	{
		// printk("WRR CPUID %d - load_balance did not find any eligible task.\n",smp_processor_id());
	}
	#endif 
}

void trigger_load_balance_wrr(struct rq *rq) 
{
	// Master handles load balancing. (Every 2000 ms)
	struct wrr_rq *wrr_rq = &cpu_rq(getMasterCPU_wrr())->wrr;
	if(smp_processor_id() == getMasterCPU_wrr())
	{
		#if __WRR_SCHED_DEBUG
		wrr_rq->debugCounter++;
		if (wrr_rq->debugCounter >= __WRR_DEBUG_TICKS) // 20 Secs.
		{
			wrr_rq->debugCounter = 0;
			printk("WRR CPUID %d - Current WRR queue status.\n",smp_processor_id());
			print_all_wrr_rq();
		}
		#endif
		wrr_rq->balanceCounter++;
		if (wrr_rq->balanceCounter >= __WRR_BALANCE_TICKS)
		{
			// #if __WRR_SCHED_DEBUG
			// printk("WRR CPUID %d - load_balance triggered.\n",smp_processor_id());
			// #endif 
			wrr_rq->balanceCounter = 0;
			load_balance_wrr(rq);
		}
	}
}

void init_wrr_rq(struct wrr_rq *wrr_rq, int CPUID)
{
    #if __WRR_SCHED_DEBUG
	printk("WRR CPUID %d - init_wrr_rq called.\n",smp_processor_id());
	#endif 
	wrr_rq->balanceCounter = 0;
	wrr_rq->debugCounter = 0;
	wrr_rq->CPUID = CPUID;
	wrr_rq->wrr_nr_running = 0;
	wrr_rq->total_weight = 0;
	INIT_LIST_HEAD(&wrr_rq->queue_head);

	print_wrr_rq(wrr_rq);
}

__init void init_sched_wrr_class(void)
{
    #if __WRR_SCHED_DEBUG
	printk("WRR CPUID %d - init_sched_wrr_class called.\n",smp_processor_id());
	#endif 
	
}

static void enqueue_task_wrr(struct rq *rq, struct task_struct *p, int flags)
{
	struct wrr_rq *wrr_rq = &rq->wrr;
	struct sched_wrr_entity *wrr = &p->wrr;

	#if __WRR_SCHED_DEBUG
	printk("WRR CPUID %d - enqueue_task_wrr called.\n",smp_processor_id());
	#endif 

	print_wrr_rq(wrr_rq);

	// Add the target task p's wrr node to the tail of current CPU's wrr runque's queue.
	list_add_tail(&wrr->queue_node, &wrr_rq->queue_head);

	wrr->pid = (int)p->pid;
	wrr_rq->wrr_nr_running++;
	wrr_rq->total_weight += wrr->weight;
	add_nr_running(rq, 1);

	// If the target runqueue is of the master CPU, set the time slice to zero,
	// so that it can be migrated as soon as possible.
	if (cpu_of(rq) != getMasterCPU_wrr())
	{
		wrr->time_slice = __WRR_TIMESLICE * (wrr -> weight);
	}
	else
	{
		wrr->time_slice = 0;
		cpu_rq(getMasterCPU_wrr())->wrr.balanceCounter = __WRR_BALANCE_TICKS;
		resched_curr(rq);
	}

	#if __WRR_SCHED_DEBUG
	printk("WRR CPUID %d - Enqueued task pid %d to WRR runque (CPU %d).\n",smp_processor_id(), wrr->pid, wrr_rq->CPUID);
	print_wrr_rq(wrr_rq);
	#endif
		
}

static void dequeue_task_wrr(struct rq *rq, struct task_struct *p, int flags)
{
	struct wrr_rq *wrr_rq = &rq->wrr;
	struct sched_wrr_entity *wrr = &p->wrr;
	
    #if __WRR_SCHED_DEBUG
	printk("WRR CPUID %d - dequeue_task_wrr called.\n",smp_processor_id());
	#endif 
	
	print_wrr_rq(wrr_rq);

	// Remove target task's wrr node from the runqueue
	list_del(&wrr->queue_node);
	wrr_rq->wrr_nr_running--;
	wrr_rq->total_weight -= wrr->weight;
	sub_nr_running(rq, 1);
	#if __WRR_SCHED_DEBUG
	printk("WRR CPUID %d - Dequeued task pid %d from WRR runque (CPU %d).\n",smp_processor_id(), wrr->pid, wrr_rq->CPUID);
	print_wrr_rq(wrr_rq);
	#endif 
}

static void yield_task_wrr(struct rq *rq)
{
	struct task_struct *curr = rq->curr;
	struct wrr_rq *wrr_rq = &rq->wrr;
	struct sched_wrr_entity *wrr = &curr->wrr;

    #if __WRR_SCHED_DEBUG
	printk("WRR CPUID %d - yield_task_wrr called.\n",smp_processor_id());
	#endif 
	
	print_wrr_rq(wrr_rq);

	// Move current task's wrr node to the end of the runqueue
	list_move_tail(&wrr->queue_node, &wrr_rq->queue_head);

	#if __WRR_SCHED_DEBUG
	printk("WRR CPUID %d - Yielded task pid %d from WRR runque (CPU %d).\n",smp_processor_id(), wrr->pid, wrr_rq->CPUID);
	print_wrr_rq(wrr_rq);
	#endif 
}

static bool yield_to_task_wrr(struct rq *rq, struct task_struct *p, bool preempt)
{
    #if __WRR_SCHED_DEBUG
	printk("WRR CPUID %d - yield_to_task_wrr called.\n",smp_processor_id());
	#endif 

	// struct sched_wrr_entity *wrr = &p->wrr;

	// //if (!se->on_rq || throttled_hierarchy(cfs_rq_of(se)))
	// //	return false;

	// /* Tell the scheduler that we'd really like pse to run next. */
	
	// //set_next_buddy(wrr);

	// yield_task_wrr(rq);


    return false;
}

static void check_preempt_curr_wrr(struct rq *rq, struct task_struct *p, int flags)
{
    #if __WRR_SCHED_DEBUG
	printk("WRR CPUID %d - check_preempt_curr_wrr called.\n",smp_processor_id());
	#endif 
	//same as check_preempt_curr in core.c
	//do we need it?
	
	// const struct sched_class *class;

	// if (p->sched_class == rq->curr->sched_class) {
	// 	rq->curr->sched_class->check_preempt_curr(rq, p, flags);
	// } else {
	// 	for_each_class(class) {
	// 		if (class == rq->curr->sched_class)
	// 			break;
	// 		if (class == p->sched_class) {
	// 			resched_curr(rq);
	// 			break;
	// 		}
	// 	}
	// }

	// /*
	//  * A queue event has occurred, and we're going to schedule.  In
	//  * this case, we can save a useless back to back clock update.
	//  */
	// if (task_on_rq_queued(rq->curr) && test_tsk_need_resched(rq->curr))
	// 	rq_clock_skip_update(rq, true);
}

static struct task_struct *pick_next_task_wrr(struct rq *rq, struct task_struct *prev, struct rq_flags *rf)
{
	struct wrr_rq *wrr_rq = &rq->wrr;
	// struct sched_wrr_entity *prevWrr;
	// struct rq_flags flags;
	struct sched_wrr_entity *nextWrr;
	struct task_struct *task;


    #if __WRR_SCHED_DEBUG
	//printk("WRR CPUID %d - pick_next_task_wrr called.\n",smp_processor_id());
	//print_wrr_rq(wrr_rq);
	#endif 
	// if (rq != task_rq_lock(prev, &flags))
	// {
	// 	printk("WRR CPUID %d ERROR - pick_next_task_wrr previous task is not part of given runque.\n",smp_processor_id());
	// }
	// Now get the first entry in list.
	nextWrr = list_first_entry_or_null(&wrr_rq->queue_head, struct sched_wrr_entity, queue_node);

	// If list empty...
	if(!nextWrr)
	{
		//printk("WRR CPUID %d - pick_next_task_wrr runqueue empty (CPU %d).\n",smp_processor_id(), wrr_rq->CPUID);
		return NULL;
	}
	// Set time slice
	if (cpu_of(rq) != getMasterCPU_wrr())
	{
		nextWrr->time_slice = __WRR_TIMESLICE * (nextWrr -> weight);
	}
	else
	{
		nextWrr->time_slice = 0;
		cpu_rq(getMasterCPU_wrr())->wrr.balanceCounter = __WRR_BALANCE_TICKS;
		return __WRR_MASTER_TASK;
	}

	#if __WRR_SCHED_DEBUG
	// printk("WRR CPUID %d - pick_next_task_wrr Picked task pid %d from WRR runque (CPU %d), as the next task.\n",smp_processor_id(), nextWrr->pid, wrr_rq->CPUID);
	// print_wrr_rq(wrr_rq);
	#endif 
	// __task_rq_unlock(rq, &flags);
	task = container_of(nextWrr, struct task_struct, wrr);
	//Check if runnable on current CPU before returning.
	return task;
}

static void put_prev_task_wrr(struct rq *rq, struct task_struct *prev)
{
    #if __WRR_SCHED_DEBUG
	printk("WRR CPUID %d - put_prev_task_wrr called.\n",smp_processor_id());
	#endif 
}

#ifdef CONFIG_SMP
static int select_task_rq_wrr(struct task_struct *p, int task_cpu, int sd_flag, int flags)
{
	int i;
	int minWeight = INT_MAX;
	int targCpu = getMasterCPU_wrr();
	#if __WRR_SCHED_DEBUG
	printk("WRR CPUID %d - select_task_rq_wrr called.\n",smp_processor_id());
	print_all_wrr_rq();
	#endif 

	// Get CPU with the minimum weight sum.
	rcu_read_lock();
	for_each_possible_cpu(i)
	{
		struct rq *rq = cpu_rq(i);
		struct wrr_rq *wrr_rq = &rq->wrr;
		// Check if the task is runnable on target CPU.
		if (checkRunnableCPU(i, p) && wrr_rq->total_weight < minWeight)
		{
			targCpu = i;
			minWeight = wrr_rq->total_weight;
		}
	}
	rcu_read_unlock();
	#if __WRR_SCHED_DEBUG
	printk("WRR CPUID %d - select_task_rq_wrr returned CPU %d.\n",smp_processor_id(), targCpu);
	#endif 
	return targCpu;
}
static void migrate_task_rq_wrr(struct task_struct *p)
{
    #if __WRR_SCHED_DEBUG
	printk("WRR CPUID %d - migrate_task_rq_wrr called.\n",smp_processor_id());
	#endif 
}
static void task_woken_wrr(struct rq *this_rq, struct task_struct *task)
{
    #if __WRR_SCHED_DEBUG
	printk("WRR CPUID %d - task_woken_wrr called.\n",smp_processor_id());
	#endif 
}
static void set_cpus_allowed_wrr(struct task_struct *p, const struct cpumask *newmask)
{
    #if __WRR_SCHED_DEBUG
	printk("WRR CPUID %d - set_cpus_allowed_wrr called.\n",smp_processor_id());
	#endif 
}
static void rq_online_wrr(struct rq *rq)
{
    #if __WRR_SCHED_DEBUG
	printk("WRR CPUID %d - rq_online_wrr called.\n",smp_processor_id());
	#endif 
}
static void rq_offline_wrr(struct rq *rq)
{
    #if __WRR_SCHED_DEBUG
	printk("WRR CPUID %d - rq_offline_wrr called.\n",smp_processor_id());
	#endif 
}

#endif

static void set_curr_task_wrr(struct rq *rq)
{
    #if __WRR_SCHED_DEBUG
	printk("WRR CPUID %d - set_curr_task_wrr called.\n",smp_processor_id());
	#endif 

	// struct sched_wrr_entity *se = &rq->curr->se;

}

static void task_tick_wrr(struct rq *rq, struct task_struct *curr, int queued)
{
	struct wrr_rq *wrr_rq = &rq->wrr;
	struct sched_wrr_entity *wrr = &curr->wrr;
	
	// If there are time slices remaining...
	if (wrr->time_slice)
	{
		wrr->time_slice--;
	}
	else
	{
		// Set time slice
		wrr->time_slice = __WRR_TIMESLICE * (wrr -> weight);
		// If current task is not the only task in the runqueue...
		if (wrr_rq->queue_head.next != wrr_rq->queue_head.prev)
		{
			// Move current task's wrr node to the end of the runqueue
			list_move_tail(&wrr->queue_node, &wrr_rq->queue_head);
		}
		resched_curr(rq);
		// Signal the need of rescheduling.
		
	}
}

static void task_fork_wrr(struct task_struct *p)
{
	struct sched_wrr_entity *parentWrr = &current->wrr;
	struct sched_wrr_entity *childWrr = &p->wrr;
	
    #if __WRR_SCHED_DEBUG
	printk("WRR CPUID %d - task_fork_wrr called.\n",smp_processor_id());
	#endif 
	childWrr->weight = parentWrr->weight;
}
static void task_dead_wrr(struct task_struct *p)
{
    #if __WRR_SCHED_DEBUG
	printk("WRR CPUID %d - task_dead_wrr called.\n",smp_processor_id());
	#endif 
}
static void prio_changed_wrr(struct rq *rq, struct task_struct *p, int oldprio)
{
    #if __WRR_SCHED_DEBUG
	printk("WRR CPUID %d - prio_changed_wrr called.\n",smp_processor_id());
	#endif 
}
static void switched_from_wrr(struct rq *rq, struct task_struct *p)
{
    #if __WRR_SCHED_DEBUG
	printk("WRR CPUID %d - switched_from_wrr called.\n",smp_processor_id());
	#endif 
}
static void switched_to_wrr(struct rq *rq, struct task_struct *p)
{
    #if __WRR_SCHED_DEBUG
	printk("WRR CPUID %d - switched_to_wrr called.\n",smp_processor_id());
	#endif 
}
static unsigned int get_rr_interval_wrr(struct rq *rq, struct task_struct *task)
{
    #if __WRR_SCHED_DEBUG
	printk("WRR CPUID %d - get_rr_interval_wrr called.\n",smp_processor_id());
	#endif 
    return 0;
}
static void update_curr_wrr(struct rq *rq)
{
    #if __WRR_SCHED_DEBUG
	printk("WRR CPUID %d - update_curr_wrr called.\n",smp_processor_id());
	#endif 

}

const struct sched_class wrr_sched_class = 
{
	.next			= &fair_sched_class,
	.enqueue_task		= enqueue_task_wrr,
	.dequeue_task		= dequeue_task_wrr,
	.yield_task		= yield_task_wrr,
	.yield_to_task		= yield_to_task_wrr,

	.check_preempt_curr	= check_preempt_curr_wrr,

	.pick_next_task		= pick_next_task_wrr,
	.put_prev_task		= put_prev_task_wrr,

#ifdef CONFIG_SMP
	.select_task_rq		= select_task_rq_wrr,
	.migrate_task_rq	= migrate_task_rq_wrr,

    .task_woken = task_woken_wrr,
    .set_cpus_allowed	= set_cpus_allowed_wrr,

	.rq_online		= rq_online_wrr,
	.rq_offline		= rq_offline_wrr,
#endif
	.set_curr_task          = set_curr_task_wrr,
	.task_tick		= task_tick_wrr,
	.task_fork		= task_fork_wrr,
    .task_dead		= task_dead_wrr,

	.prio_changed		= prio_changed_wrr,
	.switched_from		= switched_from_wrr,
	.switched_to		= switched_to_wrr,

	.get_rr_interval	= get_rr_interval_wrr,

	.update_curr		= update_curr_wrr,
};