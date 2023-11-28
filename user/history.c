//
// Created by PQ on 11/15/2023.
//

#include "../kernel/types.h"
#include "../kernel/stat.h"
#include "../user/user.h"


int
main(int argc, char *argv[])
{

    if (argc == 2) {
        history(atoi(argv[1]));
    } else {
        history(-1);
    }
    exit(0);
}
