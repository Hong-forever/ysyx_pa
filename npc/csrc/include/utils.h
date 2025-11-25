#ifndef __UTILS_H__
#define __UTILS_H__


#define COLOR_RED "\033[1;31m"
#define COLOR_GREEN "\033[1;32m"
#define COLOR_BLUE "\033[1;34m"
#define COLOR_END "\033[0m"

enum { NPC_RUNNING, NPC_STOP, NPC_END, NPC_QUIT };

typedef struct {
    int state;
    int halt_pc;
    int halt_ret;
} NPCState;

extern NPCState npc_state;

#endif