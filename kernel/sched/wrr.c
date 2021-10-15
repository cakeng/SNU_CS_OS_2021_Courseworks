#include "sched.h"
#include <linux/slab.h>
#include <linux/types.h>

#define __WRR_SCHED_DEBUG 1

void init_wrr_rq(struct wrr_rq *wrr_rq)
{
    #if __WRR_SCHED_DEBUG
	printk("WRR - init_wrr_rq called.\n");
	#endif 
	wrr_rq->wrr_nr_running = 0;
	INIT_LIST_HEAD(&wrr_rq->queue);
}
__init void init_sched_wrr_class(void)
{
    #if __WRR_SCHED_DEBUG
	printk("WRR - init_sched_wrr_class called.\n");
	#endif 
}

static void enqueue_task_wrr(struct rq *rq, struct task_struct *p, int flags)
{
    #if __WRR_SCHED_DEBUG
	printk("WRR - enqueue_task_wrr called.\n");
	#endif 
}
static void dequeue_task_wrr(struct rq *rq, struct task_struct *p, int flags)
{
    #if __WRR_SCHED_DEBUG
	printk("WRR - dequeue_task_wrr called.\n");
	#endif 
}
static void yield_task_wrr(struct rq *rq)
{
    #if __WRR_SCHED_DEBUG
	printk("WRR - yield_task_wrr called.\n");
	#endif 
}
static bool yield_to_task_wrr(struct rq *rq, struct task_struct *p, bool preempt)
{
    #if __WRR_SCHED_DEBUG
	printk("WRR - yield_to_task_wrr called.\n");
	#endif 
    return false;
}
static void check_preempt_curr_wrr(struct rq *rq, struct task_struct *p, int flags)
{
    #if __WRR_SCHED_DEBUG
	printk("WRR - check_preempt_curr_wrr called.\n");
	#endif 
}
static struct task_struct *pick_next_task_wrr(struct rq *rq, struct task_struct *prev, struct rq_flags *rf)
{
    #if __WRR_SCHED_DEBUG
	printk("WRR - pick_next_task_wrr called.\n");
	#endif 
    return NULL;
}
static void put_prev_task_wrr(struct rq *rq, struct task_struct *prev)
{
    #if __WRR_SCHED_DEBUG
	printk("WRR - put_prev_task_wrr called.\n");
	#endif 
}
#ifdef CONFIG_SMP
static int select_task_rq_wrr(struct task_struct *p, int task_cpu, int sd_flag, int flags)
{
    #if __WRR_SCHED_DEBUG
	printk("WRR - select_task_rq_wrr called.\n");
	#endif 
    return 0;
}
static void migrate_task_rq_wrr(struct task_struct *p)
{
    #if __WRR_SCHED_DEBUG
	printk("WRR - migrate_task_rq_wrr called.\n");
	#endif 
}
static void task_woken_wrr(struct rq *this_rq, struct task_struct *task)
{
    #if __WRR_SCHED_DEBUG
	printk("WRR - task_woken_wrr called.\n");
	#endif 
}
static void set_cpus_allowed_wrr(struct task_struct *p, const struct cpumask *newmask)
{
    #if __WRR_SCHED_DEBUG
	printk("WRR - set_cpus_allowed_wrr called.\n");
	#endif 
}
static void rq_online_wrr(struct rq *rq)
{
    #if __WRR_SCHED_DEBUG
	printk("WRR - rq_online_wrr called.\n");
	#endif 
}
static void rq_offline_wrr(struct rq *rq)
{
    #if __WRR_SCHED_DEBUG
	printk("WRR - rq_offline_wrr called.\n");
	#endif 
}

#endif
static void set_curr_task_wrr(struct rq *rq)
{
    #if __WRR_SCHED_DEBUG
	printk("WRR - set_curr_task_wrr called.\n");
	#endif 
}
static void task_tick_wrr(struct rq *rq, struct task_struct *curr, int queued)
{
    #if __WRR_SCHED_DEBUG
	printk("WRR - task_tick_wrr called.\n");
	#endif 
}
static void task_fork_wrr(struct task_struct *p)
{
    #if __WRR_SCHED_DEBUG
	printk("WRR - task_fork_wrr called.\n");
	#endif 
}
static void task_dead_wrr(struct task_struct *p)
{
    #if __WRR_SCHED_DEBUG
	printk("WRR - task_dead_wrr called.\n");
	#endif 
}
static void prio_changed_wrr(struct rq *rq, struct task_struct *p, int oldprio)
{
    #if __WRR_SCHED_DEBUG
	printk("WRR - prio_changed_wrr called.\n");
	#endif 
}
static void switched_from_wrr(struct rq *rq, struct task_struct *p)
{
    #if __WRR_SCHED_DEBUG
	printk("WRR - switched_from_wrr called.\n");
	#endif 
}
static void switched_to_wrr(struct rq *rq, struct task_struct *p)
{
    #if __WRR_SCHED_DEBUG
	printk("WRR - switched_to_wrr called.\n");
	#endif 
}
static unsigned int get_rr_interval_wrr(struct rq *rq, struct task_struct *task)
{
    #if __WRR_SCHED_DEBUG
	printk("WRR - get_rr_interval_wrr called.\n");
	#endif 
    return 0;
}
static void update_curr_wrr(struct rq *rq)
{
    #if __WRR_SCHED_DEBUG
	printk("WRR - update_curr_wrr called.\n");
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
