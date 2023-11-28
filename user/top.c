#include "kernel/types.h"
#include "kernel/param.h"
#include "kernel/spinlock.h"
#include "kernel/riscv.h"
#include "kernel/stat.h"
#include "kernel/proc.h"
#include "user/user.h"


int
main(int argc, char *argv[])
{
    static char *states[] = {
            [UNUSED]    "unused",
            [USED]      "used",
            [SLEEPING]  "sleeping ",
            [RUNNABLE]  "runnable",
            [RUNNING]   "running ",
            [ZOMBIE]    "zombie"
    };

    struct top t;
   top(&t);

    printf("total process : ");
    printf("%d\n",t.total);
    printf("running process : ");
    printf("%d\n",t.running);
    printf("waiting process : ");
    printf("%d\n",t.waiting);

    printf("NAME\tPID\tPPID\tSTATE\n");
    for (int i = 0; i < t.total; ++i) {
        printf("%s\t%d\t%d\t%s\n", t.info[i].name, t.info[i].pid, t.info[i].ppid, states[t.info[i].state]);
    }
    exit(0);
}
