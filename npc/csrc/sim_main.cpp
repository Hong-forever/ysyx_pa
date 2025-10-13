
#include <stdio.h>
#include <stdlib.h>
#include <assert.h>

#include "Vtest.h"
#include "verilated.h"


#define WAVE_FST 0

#if WAVE_FST
    #include "verilated_fst_c.h"    //export fst
#else                               
    #include "verilated_vcd_c.h"    //export vcd
#endif


int main(int argc, char* argv[]) {
    VerilatedContext* contextp = new VerilatedContext;
    contextp->commandArgs(argc, argv);
    Vtest* top = new Vtest{contextp};

#if WAVE_FST
    VerilatedFstC* tfp = new VerilatedFstC;
#else                              
    VerilatedVcdC* tfp = new VerilatedVcdC;
#endif
    contextp->traceEverOn(true);
    top->trace(tfp, 0);

#if WAVE_FST
    tfp->open("wave.fst");
#else
    tfp->open("wave.vcd");
#endif

    while (!contextp->gotFinish()) {
        int a = rand() & 1;
        int b = rand() & 1;
        top->a = a;
        top->b = b;
        top->eval();
        printf("a = %d, b = %d, f = %d\n", a, b, top->f);

        tfp->dump(contextp->time());
        contextp->timeInc(1);

        assert(top->f == (a ^ b));
    }
    delete top;
    tfp->close();
    delete contextp;
    return 0;
}
