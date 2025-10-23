/***************************************************************************************
* Copyright (c) 2014-2024 Zihao Yu, Nanjing University
*
* NEMU is licensed under Mulan PSL v2.
* You can use this software according to the terms and conditions of the Mulan PSL v2.
* You may obtain a copy of Mulan PSL v2 at:
*          http://license.coscl.org.cn/MulanPSL2
*
* THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND,
* EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT,
* MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
*
* See the Mulan PSL v2 for more details.
***************************************************************************************/

#include <isa.h>
#include <cpu/cpu.h>
#include <memory/paddr.h>
#include <readline/readline.h>
#include <readline/history.h>
#include "sdb.h"

static int is_batch_mode = false;

void init_regex();
void init_wp_pool();

/* We use the `readline' library to provide more flexibility to read from stdin. */
static char* rl_gets() {
  static char *line_read = NULL;

  if (line_read) {
    free(line_read);
    line_read = NULL;
  }

  line_read = readline("(nemu) ");

  if (line_read && *line_read) {
    add_history(line_read);
  }

  return line_read;
}

static int cmd_c(char *args) {
  cpu_exec(-1);
  return 0;
}


static int cmd_q(char *args) {
  return -1;
}

static int cmd_help(char *args);

static int cmd_si(char *args) {
    char *arg = strtok(args, " ");
    if(arg == NULL) {
        cpu_exec(1);
        //printf("Exe 1 inst\n"); 
    } else {
        for(char *p = arg; *p != '\0'; p++) {
            if(!isdigit(*p)) {
                printf("Error: need a number\n");
                return 0;
            }
        }
        
        int n = atoi(arg);
        if(n <= 0) {
            printf("Error: Must be a positive number\n");
            return 0;
        }

        cpu_exec((uint64_t)n);
        //printf("Exe %d %s\n", n, n>1?"insts":"inst");
    }
    
    return 0;
}

void info_cmd_print() {
    printf("info <subcommand>\n");
    printf(" r  - print Integer regs status\n");
    printf(" w  - print watching point status\n");
}

static int cmd_info(char *args) {
    char *arg = strtok(args, " ");
    if(arg == NULL) {
        info_cmd_print();
    } else {
        char cmd_char = arg[0];
        if(arg[1] != '\0') {
            printf("---Please input correct cmd---\n");
            info_cmd_print();
        } else {
            switch(cmd_char) {
                case 'r': isa_reg_display(); break;
                case 'w': break;
                default : 
                    printf("---Please input correct cmd---\n");
                    info_cmd_print();
                    break;
            }
        }       
    }
    return 0;
}

static int cmd_x(char *args) {
    char *arg = strtok(args, " ");
    char *expr_arg = strtok(NULL, " ");
    if(arg == NULL || expr_arg == NULL) {
        printf("Error: Please input: x <N> <EXPR>\n");
    } else {
        int n = atoi(arg);
        char *endptr;
        word_t expr = (word_t)strtol(expr_arg, &endptr, 16);
        if(n <= 0 || *endptr != '\0' || (expr < (word_t)PMEM_LEFT || expr >= (word_t)PMEM_RIGHT)) {
            printf("Please input correctly\n");
            return 0;
        }
        for(int i=0; i<n; i++) {
            printf("addr-0x%08x --> inst: %08x\n", expr+4*i, paddr_read(expr+4*i, 4));
        }
    }
    return 0;
}

static int cmd_p(char *args) {
    if(args == NULL) {
        printf("p <expr>\n");
        printf("eg: p 1+2\n");
        return 0;
    }

    //printf("%s\n", args);

    bool success;
    word_t result = expr(args, &success);

    if(success) {
        printf("result: 0x%08x(%u)\n", result, result);
    } else {
        printf("Error to evaluate\n");
    }

    return success ? 0 : -1;
}

static struct {
  const char *name;
  const char *description;
  int (*handler) (char *);
} cmd_table [] = {
  { "help", "Display information about all supported commands", cmd_help },
  { "c", "Continue the execution of the program", cmd_c },
  { "q", "Exit NEMU", cmd_q },
  { "si", "Execute inst step", cmd_si },
  { "info", "Print register or monitoring point information", cmd_info },
  { "x", "Find the value of the expression EXPR and use the result as the starting memory. The address is output in hexadecimal form as N consecutive 4-bytes", cmd_x },
  { "p", "Find the value of the expression EXPR", cmd_p },
//  { "w", "Stop if EXPR changes", cmd_w },
//  { "d", "Delete the monitor point with serial number N", cmd_d },


  /* TODO: Add more commands */

};

#define NR_CMD ARRLEN(cmd_table)

static int cmd_help(char *args) {
  /* extract the first argument */
  char *arg = strtok(args, " ");
  int i;

  if (arg == NULL) {
    /* no argument given */
    for (i = 0; i < NR_CMD; i ++) {
      printf("%s - %s\n", cmd_table[i].name, cmd_table[i].description);
    }
  }
  else {
    for (i = 0; i < NR_CMD; i ++) {
      if (strcmp(arg, cmd_table[i].name) == 0) {
        printf("%s - %s\n", cmd_table[i].name, cmd_table[i].description);
        return 0;
      }
    }
    printf("Unknown command '%s'\n", arg);
  }
  return 0;
}

void sdb_set_batch_mode() {
  is_batch_mode = true;
}

void sdb_mainloop() {
  if (is_batch_mode) {
    cmd_c(NULL);
    return;
  }

  for (char *str; (str = rl_gets()) != NULL; ) {
    char *str_end = str + strlen(str);

    /* extract the first token as the command */
    char *cmd = strtok(str, " ");
    if (cmd == NULL) { continue; }

    /* treat the remaining string as the arguments,
     * which may need further parsing
     */
    char *args = cmd + strlen(cmd) + 1;
    if (args >= str_end) {
      args = NULL;
    }

#ifdef CONFIG_DEVICE
    extern void sdl_clear_event_queue();
    sdl_clear_event_queue();
#endif

    int i;
    for (i = 0; i < NR_CMD; i ++) {
      if (strcmp(cmd, cmd_table[i].name) == 0) {
        if (cmd_table[i].handler(args) < 0) { return; }
        break;
      }
    }

    if (i == NR_CMD) { printf("Unknown command '%s'\n", cmd); }
  }
}

void init_sdb() {
  /* Compile the regular expressions. */
  init_regex();

  /* Initialize the watchpoint pool. */
  init_wp_pool();
}
