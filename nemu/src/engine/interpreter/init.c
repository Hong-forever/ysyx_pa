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

#include <cpu/cpu.h>
#include "../../monitor/sdb/sdb.h"
#include <ctype.h>

void sdb_mainloop();

void engine_start() {
#ifdef CONFIG_TARGET_AM
  cpu_exec(-1);
#else
  /* Receive commands from user. */
  FILE *fp = fopen("/home/hhh/Desktop/ysyx/ysyx-workbench/nemu/tools/gen-expr/input.txt" , "r");
  if(fp == NULL) {
      printf("Error to open file\n");
  }

  char expr_buf[65536];
  uint32_t expected;
  bool success = 0;
  uint32_t pass_num = 0;
    
  for(int i=0; i<1000; i++) {
    int a = fscanf(fp, "%u %[^\n]", &expected, expr_buf);
    assert(a == 2);
    for(char *p=expr_buf; *p; p++) {
        if(*p == 'u' && (p == expr_buf || !isalnum(*(p-1)))) {
            memmove(p, p+1, strlen(p));
            p--;
        }
    }
    
    uint32_t actual = expr(expr_buf, &success);

    if(success && actual == expected) {
        printf("success: %u\n", i);
        pass_num++;
    } else {
        printf("Error %u\nExpected: %u, Actua: %u, %s\n", i, expected, actual,expr_buf);
        /* assert(0); */
    }
  }

  fclose(fp);
  printf("Pass %u\n", pass_num);


  sdb_mainloop();
#endif
}
