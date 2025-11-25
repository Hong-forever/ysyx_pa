#include "common.h"
#include "utils.h"

static TOP_NAME dut;

#ifdef CONFIG_USE_NVBOARD
#include <nvboard.h>
void nvboard_bind_all_pins(TOP_NAME *top);

void nvboard()
{
    nvboard_bind_all_pins(&dut);
    nvboard_init();
}
#endif

extern "C" void trap(int reg_data, int halt_pc)
{
    npc_state.halt_pc = halt_pc;
    npc_state.halt_ret = reg_data + 1;
}

static void single_cycle()
{
    dut.clk = 0;
    dut.eval();
    dut.clk = 1;
    dut.eval();
}

void reset(int n)
{
    dut.rst = 1;
    while (n-- > 0)
        single_cycle();
    dut.rst = 0;
}

#define CONFIG_WATCHPOINT
void check_watchpoint();

static void exec_once()
{
    single_cycle();
    // trace_and_difftest(&s, cpu.pc);
    IFDEF(CONFIG_WATCHPOINT, check_watchpoint());
}

static void execute(uint64_t n)
{
    while (n-- > 0) {
        exec_once();
        if (npc_state.halt_ret != 0)
        {
            npc_state.state = NPC_END;
            break;
        } 
        else if (npc_state.state == NPC_STOP) {
            break;
        }
        IFDEF(CONFIG_USE_NVBOARD, nvboard_update());
    }

}

void cpu_exec(uint64_t n)
{
    switch (npc_state.state)
    {
        case NPC_END: 
        case NPC_QUIT: 
            printf("Program execution has ended. To restart the program, exit NPC and run again\n");
            return ;
        default: 
            npc_state.state = NPC_RUNNING;
            break;
    }

    execute(n);

    switch (npc_state.state)
    {
        case NPC_END:
            if (npc_state.halt_ret == 1) {
                printf(COLOR_GREEN "[=>>> HIT GOOD TRAP at pc = 0x%08x\n" COLOR_END, npc_state.halt_pc);
            } else if (npc_state.halt_ret == 2) {
                printf(COLOR_RED "[=>>> HIT BAD TRAP at pc = 0x%08x\n" COLOR_END, npc_state.halt_pc);
            }
            break;
        // case NPC_QUIT:
        //     break;

        default:
            break;
    }
}
