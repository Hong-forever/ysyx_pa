
#include <stdio.h>
#include <stdlib.h>
#include <assert.h>

#include "Vtop.h"
#include <verilated.h>


#define WAVE_FST 1

#if WAVE_FST
    #include "verilated_fst_c.h"    //export fst
    VerilatedFstC* tfp = new VerilatedFstC;
#else                               
    #include "verilated_vcd_c.h"    //export vcd
    VerilatedVcdC* tfp = new VerilatedVcdC;
#endif


int main(int argc, char* argv[]) {
    VerilatedContext* contextp = new VerilatedContext;
    contextp->commandArgs(argc, argv);
    Vtop* top = new Vtop{contextp};

    contextp->traceEverOn(true);
    top->trace(tfp, 99);

#if WAVE_FST
    tfp->open("build/logs/wave.fst");
#else
    tfp->open("build/logs/wave.vcd");
#endif

    int cycle = 50;

    while (cycle/*!contextp->gotFinish()*/) {
        int a = rand() & 1;
        int b = rand() & 1;
        top->a = a;
        top->b = b;
        top->eval();
        printf("a = %d, b = %d, f = %d\n", a, b, top->f);

        tfp->dump(contextp->time());
        contextp->timeInc(1);

        assert(top->f == (a ^ b));
        cycle--;
    }
    delete top;
    tfp->close();
    delete contextp;
    return 0;
}
