#include "sched.h"
#include <linux/slab.h>
#include <linux/types.h>
#include <linux/smp.h>
#include <linux/list.h>


void init_wrr_rq(struct wrr_rq *wrr_rq)
{
    #if __WRR_SCHED_DEBUG
	printk("WRR CPUID %d - init_wrr_rq called.\n",smp_processor_id());
	#endif 
	wrr_rq->wrr_nr_running = 0;
	INIT_LIST_HEAD(&wrr_rq->queue);
	wrr_rq->total_weight = 0;

	
}
__init void init_sched_wrr_class(void)
{
    #if __WRR_SCHED_DEBUG
	printk("WRR CPUID %d - init_sched_wrr_class called.\n",smp_processor_id());
	#endif 
	
}

static void enqueue_task_wrr(struct rq *rq, struct task_struct *p, int flags)
{
    #if __WRR_SCHED_DEBUG
	printk("WRR CPUID %d - enqueue_task_wrr called.\n",smp_processor_id());
	#endif 

	struct wrr_rq *wrr_rq = &rq->wrr;
	struct sched_wrr_entity *wrr = &p->wrr;

	//if(wrr_se->on_wrr_rq) 
	//	return;
	//ALREADY ON CASE


	list_add_tail(&wrr->queue_node, &wrr_rq->queue);

	struct list_head *new = &wrr->queue_node;
	struct list_head *next =  &wrr_rq->queue;
	struct list_head *prev = head->prev;

	next->prev = new;
	new->next = next;
	new->prev = prev;
	prev->next = new;

	wrr_rq->wrr_nr_running++;
	wrr_rq->total_weight += wrr->weight;
	add_nr_running(rq, 1);


	//wrr_se->on_wrr_rq = 1; 

}
static void dequeue_task_wrr(struct rq *rq, struct task_struct *p, int flags)
{
    #if __WRR_SCHED_DEBUG
	printk("WRR CPUID %d - dequeue_task_wrr called.\n",smp_processor_id());
	#endif 
	
	struct wrr_rq *wrr_rq = &rq->wrr;
	struct sched_wrr_entity *wrr = &p->wrr;

	list_del(&wrr->queue_node);
	wrr_rq->wrr_nr_running--;
	wrr_rq->total_weight -= wrr->weight;
	//wrr_se->on_wrr_rq = 0;//se_off
}

static void yield_task_wrr(struct rq *rq)
{
    #if __WRR_SCHED_DEBUG
	printk("WRR CPUID %d - yield_task_wrr called.\n",smp_processor_id());
	#endif 
	struct task_struct *curr = rq->curr;
	struct wrr_rq *wrr_rq = &rq->wrr;
	struct sched_wrr_entity *wrr = &curr->wrr;

	list_move_tail(&wrr->queue_node, &wrr_rq->queue);
	
	//if (unlikely(rq->nr_running == 1))
	//return;

	//clear_buddies(wrr_rq, wrr);

	//if (curr->policy != SCHED_BATCH) {
		//update_rq_clock(rq);
		/*
		 * Update run-time statistics of the 'current'.
		 */
		//update_curr(wrr_rq);
		/*
		 * Tell update_rq_clock() that we've just updated,
		 * so we don't do microscopic update in schedule()
		 * and double the fastpath cost.
		 */
		//rq_clock_skip_update(rq, true);
	//}

	//set_skip_buddy(wrr);


}

static bool yield_to_task_wrr(struct rq *rq, struct task_struct *p, bool preempt)
{
    #if __WRR_SCHED_DEBUG
	printk("WRR CPUID %d - yield_to_task_wrr called.\n",smp_processor_id());
	#endif 

	struct sched_wrr_entity *wrr = &p->wrr;

	//if (!se->on_rq || throttled_hierarchy(cfs_rq_of(se)))
	//	return false;

	/* Tell the scheduler that we'd really like pse to run next. */
	
	//set_next_buddy(wrr);

	yield_task_wrr(rq);


    return false;
}
static void check_preempt_curr_wrr(struct rq *rq, struct task_struct *p, int flags)
{
    #if __WRR_SCHED_DEBUG
	printk("WRR CPUID %d - check_preempt_curr_wrr called.\n",smp_processor_id());
	#endif 
	//same as check_preempt_curr in core.c
	//do we need it?
	
	const struct sched_class *class;

	if (p->sched_class == rq->curr->sched_class) {
		rq->curr->sched_class->check_preempt_curr(rq, p, flags);
	} else {
		for_each_class(class) {
			if (class == rq->curr->sched_class)
				break;
			if (class == p->sched_class) {
				resched_curr(rq);
				break;
			}
		}
	}

	/*
	 * A queue event has occurred, and we're going to schedule.  In
	 * this case, we can save a useless back to back clock update.
	 */
	if (task_on_rq_queued(rq->curr) && test_tsk_need_resched(rq->curr))
		rq_clock_skip_update(rq, true);
}

static struct sched_wrr_entity *__pick_next_entity(struct sched_wrr_entity *se)
{
	struct rb_node *next = rb_next(&se->run_node);

	if (!next)
		return NULL;

	return rb_entry(next, struct sched_entity, run_node);
}
static struct task_struct *pick_next_task_wrr(struct rq *rq, struct task_struct *prev, struct rq_flags *rf)
{
    #if __WRR_SCHED_DEBUG
	printk("WRR CPUID %d - pick_next_task_wrr called.\n",smp_processor_id());
	#endif 

	struct wrr_rq *wrr_rq = &rq->wrr;
	struct sched_wrr_entity *wrr_se;
	struct task_struct *p;
	int new_tasks;
	//wrr_se = __pick_next_entity(wrr_rq);

	if(wrr_se){
		wrr_se->time_slice = __WRR_TIMESLICE * (wrr_se -> weight);
	}	

	

    return NULL;
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

	struct sched_wrr_entity *se = &rq->curr->se;

}
static void task_tick_wrr(struct rq *rq, struct task_struct *curr, int queued)
{
    #if __WRR_SCHED_DEBUG
	printk("WRR CPUID %d - task_tick_wrr called.\n",smp_processor_id());
	#endif 
	struct wrr_rq *wrr_rq;
	struct sched_wrr_entity *se = &curr->se;


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