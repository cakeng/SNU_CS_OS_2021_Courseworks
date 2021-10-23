#include "sched.h"
#include <linux/slab.h>
#include <linux/types.h>
#include <linux/smp.h>
#include <linux/list.h>


void print_wrr_rq(struct wrr_rq *wrr_rq)
{
	struct list_head* queueHead = &wrr_rq->queue_head;
	struct list_head* queuePtr = queueHead;
	struct sched_wrr_entity *wrr;
	int loopI;
	#if __WRR_SCHED_DEBUG
	printk("WRR CPUID %d - WRR (CPU %d) runque status: total weight - %d, nr_running - %d.\n"
		,smp_processor_id(), wrr_rq->CPUID, wrr_rq->total_weight, wrr_rq->wrr_nr_running);
	
	if (list_empty(queuePtr))
	{
		printk("WRR CPUID %d - WRR (CPU %d) runque empty.\n",smp_processor_id(), wrr_rq->CPUID);
	}
	else
	{
		loopI = 0;
		list_for_each(queuePtr, queueHead)
		{
			loopI++;
			wrr = list_entry(queuePtr, struct sched_wrr_entity, queue_node);
			printk("WRR CPUID %d - WRR (CPU %d) runque %d th entry: PID - %d, weight - %d, time slice - %d.\n"
				,smp_processor_id(), wrr_rq->CPUID, loopI, wrr->pid, wrr->weight, wrr->time_slice);
		}
	}
	#endif 
}

void init_wrr_rq(struct wrr_rq *wrr_rq)
{
    #if __WRR_SCHED_DEBUG
	printk("WRR CPUID %d - init_wrr_rq called.\n",smp_processor_id());
	#endif 
	wrr_rq->CPUID = smp_processor_id();
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
	struct sched_wrr_entity *prevWrr = &prev->wrr;
	struct sched_wrr_entity *nextWrr;

    #if __WRR_SCHED_DEBUG
	printk("WRR CPUID %d - pick_next_task_wrr called.\n",smp_processor_id());
	#endif 

	print_wrr_rq(wrr_rq);
	// Move previous task's wrr node to the end of the runqueue
	list_move_tail(&prevWrr->queue_node, &wrr_rq->queue_head);
	#if __WRR_SCHED_DEBUG
	printk("WRR CPUID %d - Moved previous task pid %d to the end of the runqueue (CPU %d).\n",smp_processor_id(), prevWrr->pid, wrr_rq->CPUID);
	print_wrr_rq(wrr_rq);
	#endif 
	// Now get the first entry in list.
	nextWrr = list_first_entry_or_null(&wrr_rq->queue_head, struct sched_wrr_entity, queue_node);

	// If list empty for some reason...
	if(!nextWrr)
	{
		printk("WRR CPUID %d ERROR - pick_next_task_wrr runqueue empty!! (CPU %d).\n",smp_processor_id(), wrr_rq->CPUID);
		return NULL;
	}	
	// Set time slice
	nextWrr->time_slice = __WRR_TIMESLICE * (nextWrr -> weight);

	#if __WRR_SCHED_DEBUG
	printk("WRR CPUID %d - Picked task pid %d from WRR runque (CPU %d), as the next task.\n",smp_processor_id(), nextWrr->pid, wrr_rq->CPUID);
	print_wrr_rq(wrr_rq);
	#endif 

    return container_of(nextWrr, struct task_struct, wrr);
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
    #if __WRR_SCHED_DEBUG
	printk("WRR CPUID %d - select_task_rq_wrr called.\n",smp_processor_id());
	#endif 


    return 0;
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
		#if __WRR_SCHED_DEBUG
		printk("WRR CPUID %d - Zero time slice on task pid %d (CPU %d).\n",smp_processor_id(), wrr->pid, wrr_rq->CPUID);
		print_wrr_rq(wrr_rq);
		#endif 
		// If current task is not the only task in the runqueue...
		if (wrr_rq->queue_head.next != wrr_rq->queue_head.prev)
		{
			// Move current task's wrr node to the end of the runqueue
			list_move_tail(&wrr->queue_node, &wrr_rq->queue_head);
			// Inform the need of rescheduling.
			set_tsk_need_resched(curr);
		}
	}
}
static void task_fork_wrr(struct task_struct *p)
{
    #if __WRR_SCHED_DEBUG
	printk("WRR CPUID %d - task_fork_wrr called.\n",smp_processor_id());
	#endif 
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