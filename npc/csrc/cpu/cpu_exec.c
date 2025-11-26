#include "isa.h"
#include "utils.h"

static TOP_NAME dut;
int cpu_inst_valid = 0;

void reg_display();

#ifdef CONFIG_USE_NVBOARD
#include <nvboard.h>
void nvboard_bind_all_pins(TOP_NAME *top);

void nvboard()
{
    nvboard_bind_all_pins(&dut);
    nvboard_init();
}
#endif

static bool g_print_step = false;

#define MAX_INST_TO_PRINT 10
#define IRINGBUF_SIZE 256
#define IRINGBUF_LINE 20

LoopHistory_t loop_history[LOOP_HISTORY_SIZE];

#ifdef CONFIG_ITRACE
static char iringbuf[IRINGBUF_LINE][IRINGBUF_SIZE];
static int nr_inst = 0;

static void iringbuf_trace(char *logbuf) {
    if(nr_inst < IRINGBUF_LINE) {
        strncpy(iringbuf[nr_inst], logbuf, IRINGBUF_SIZE); 
        nr_inst++;     
    } else {
        for(int i=0; i<IRINGBUF_LINE-1; i++) {
            strncpy(iringbuf[i], iringbuf[i+1], IRINGBUF_SIZE);
        }
        strncpy(iringbuf[IRINGBUF_LINE-1], logbuf, IRINGBUF_SIZE);
    }
}

void iring_trace_printf() {
    if(nr_inst < IRINGBUF_LINE) {
        for(int i=0; i<nr_inst; i++) {
            printf("%s\n", iringbuf[i]);
        }
    } else {
        for(int i=0; i<IRINGBUF_LINE; i++) {
            printf("%s\n", iringbuf[i]);
        }
    }
}
#endif

void check_watchpoint();

static void trace_and_difftest(Decode _this)
{
    if(g_print_step) {
        IFDEF(CONFIG_ITRACE, printf("%s\n", _this.logbuf));
    }
    IFDEF(CONFIG_ITRACE, iringbuf_trace(_this.logbuf));
    IFDEF(CONFIG_DIFFTEST, difftest_step(_this.pc));
    IFDEF(CONFIG_WATCHPOINT, check_watchpoint());
}

#ifdef CONFIG_LOOP_DETECT
void detect_loop_pattern() { 
    static bool initialized = false;
    if(!initialized) {
        for(int i=0; i<LOOP_HISTORY_SIZE; i++) {
            loop_history[i].pc = 0;
            loop_history[i].count = 0;
        }
        initialized = true;
    }

    bool found = false;
    for(int i=0; i<LOOP_HISTORY_SIZE; i++) {
        if(loop_history[i].pc == cpu.pc) {
            loop_history[i].count++;
            found = true;
            break;
        }
    }

    if(!found) {
        int min_index = 0;
        uint32_t min_count = loop_history[0].count;
        for(int i=1; i<LOOP_HISTORY_SIZE; i++) {
            if (loop_history[i].count < min_count) {
                min_count = loop_history[i].count;
                min_index = i;
            }
        }
        loop_history[min_index].pc = cpu.pc;
        loop_history[min_index].count = 1;
    }

    for(int i = 0; i < LOOP_HISTORY_SIZE; i++) {
        if(loop_history[i].count > MAX_LOOP_COUNT) {
            printf("Detected loop pattern: PC 0x%08x executed over %u times\n", 
                    loop_history[i].pc, MAX_LOOP_COUNT);
            npc_state.state = NPC_STOP;
            break;
        }
    }
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

void assert_fail_msg() {
    IFDEF(CONFIG_ITRACE, iring_trace_printf());
    reg_display();
}

static void exec_once()
{
    single_cycle();

    // printf("cpu_inst_valid: %d\n", cpu_inst_valid);
    
    if (!cpu_inst_valid) return;

    IFDEF(CONFIG_LOOP_DETECT, detect_loop_pattern());
    
#ifdef CONFIG_ITRACE
    char *p = s.logbuf;
    p += snprintf(p, sizeof(s.logbuf), "0x%08x: ", s.pc);
    int i;
    uint8_t *inst = (uint8_t *)&s.inst;

    int ilen = 4;
    for (i = ilen-1; i >= 0; i --)
        p += snprintf(p, sizeof(s.logbuf) - (p - s.logbuf), " %02x", inst[i]);

    int ilen_max = 4;
    int space_len = ilen_max - 4;
    space_len = space_len * 3 + 5;
    memset(p, ' ', space_len);
    p += space_len;

    // printf("%p, %d, %d, %p, %d\n", p, s.logbuf + sizeof(s.logbuf) - p, s.pc, (uint8_t *)&s.inst, ilen);

    void disassemble(char *str, int size, uint64_t pc, uint8_t *code, int nbyte);
    disassemble(p, s.logbuf + sizeof(s.logbuf) - p, s.pc, (uint8_t *)&s.inst, ilen);
#endif
}

static void execute(uint64_t n)
{
    while (n-- > 0) {
        exec_once();

        if(cpu_inst_valid) {
            trace_and_difftest(s);
            cpu_inst_valid = 0;
        } else {
            n++;
        }

        if (npc_state.state == NPC_STOP || npc_state.state == NPC_ABORT) {
            break;
        }
        else if (npc_state.halt_ret != 0)
        {
            npc_state.state = NPC_END;
            break;
        }         
        IFDEF(CONFIG_USE_NVBOARD, nvboard_update());
    }

}

void cpu_exec(uint64_t n)
{
    g_print_step = (n <= MAX_INST_TO_PRINT);

    switch (npc_state.state)
    {
        case NPC_END: 
        case NPC_QUIT: 
        case NPC_ABORT:
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
        case NPC_ABORT:
            printf(COLOR_RED "[=>>> ABORT at pc = 0x%08x\n" COLOR_END, cpu.pc);
            assert_fail_msg();
            break;
        // case NPC_QUIT:
        //     break;

        default:
            break;
    }
}
