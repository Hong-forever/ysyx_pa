#include "common.h"

static TOP_NAME dut;

void nvboard_bind_all_pins(TOP_NAME *top);

int trap_flag = 0;
extern "C" void trap(int reg_data)
{
    if (reg_data == 0)  trap_flag = 1;
    else                trap_flag = 2;
}

static void single_cycle()
{
    dut.clk = 0;
    dut.eval();
    dut.clk = 1;
    dut.eval();
}

static void reset(int n)
{
    dut.rst = 1;
    while (n-- > 0)
        single_cycle();
    dut.rst = 0;
}

int main(int argc, char *argv[])
{
    nvboard_bind_all_pins(&dut);
    nvboard_init();

    init_monitor(argc, argv);

    reset(10);

    while (1) {
        nvboard_update();
        single_cycle();
        if (trap_flag == 1) {
            printf(COLOR_GREEN "[==========================================================]\n" COLOR_END);
            printf(COLOR_GREEN "[====================] HIT GOOD TRAP! [====================]\n" COLOR_END);
            printf(COLOR_GREEN "[==========================================================]\n" COLOR_END);
            return 0;
        } else if (trap_flag == 2) {
            printf(COLOR_RED "[=========================================================]\n" COLOR_END);
            printf(COLOR_RED "[====================] HIT BAD TRAP! [====================]\n" COLOR_END);
            printf(COLOR_RED "[=========================================================]\n" COLOR_END);
            return 0;
        }
    }
}
