#include "common.h"

void reset(int n);
void init_monitor(int argc, char *argv[]);
void engine_start();
int is_exit_status_bad()

void init_monoitor(int argc, char *argv[]);
void engine_start();

IFDEF(CONFIG_USE_NVBOARD, void nvboard());

int main(int argc, char *argv[])
{
    IFDEF(CONFIG_USE_NVBOARD, nvboard());

    init_monitor(argc, argv);

    reset(10);

    engine_start();

    return is_exit_status_bad();
}
