
# Clock's data structure: the occurrence priority queue

Clocks store occurrences AND their sub-clocks in a priority queue. The priority for occurrences is their scheduled time. The priority for sub-clocks is the scheduled time of their next occurrence.

Since Clocks aren't required to share a parent class or module at this time, Clocks tell sub-clocks in the queue from occurrences by storing clocks as `[:clock, clock_obj]` instead of just `clock_obj`.

When a clock's occurrences change, it should check whether the change affects its next occurrence's scheduled time. If it does, it needs to reschedule itself with its parent. Clock currently does this when occurrences are scheduled, unscheduled, or its relative_rate changes.
