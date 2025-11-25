#ifndef __UTILS_H__
#define __UTILS_H__

enum { NPC_INIT, NPC_END, NPC_QUIT };

typedef struct {
    int state;
    int halt_pc;
    int halt_ret;
} NPCState;

extern NPCState npc_state;

#endif