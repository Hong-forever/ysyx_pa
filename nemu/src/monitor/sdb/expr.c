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
#include "../../isa/riscv32/local-include/reg.h"
/* We use the POSIX regex functions to process regular expressions.
 * Type 'man regex' for more information about POSIX regex functions.
 */
#include <regex.h>

enum {
  TK_NOTYPE = 256, TK_EQ,
  TK_NEQ,
  TK_NUM,
  TK_HEX_NUM,
  TK_NEG,
  TK_REG,
  /* TODO: Add more token types */

};

static struct rule {
  const char *regex;
  int token_type;
} rules[] = {

  /* TODO: Add more rules.
   * Pay attention to the precedence level of different rules.
   */

  {" +", TK_NOTYPE},    // spaces
  {"0x[0-9a-fA-F]+", TK_HEX_NUM},
  {"[0-9]+", TK_NUM},
  {"\\+", '+'},         // plus
  {"-", '-'},
  {"\\*", '*'},
  {"/", '/'},
  {"\\(", '('},
  {"\\)", ')'},
  {"\\)", ')'},
  {"==", TK_EQ},        // equal
  {"!=", TK_NEQ},
  {"\\$[a-z0-11]+", TK_REG},
};

#define NR_REGEX ARRLEN(rules)

static regex_t re[NR_REGEX] = {};

/* Rules are used for many times.
 * Therefore we compile them only once before any usage.
 */
void init_regex() {
  int i;
  char error_msg[128];
  int ret;

  for (i = 0; i < NR_REGEX; i ++) {
    ret = regcomp(&re[i], rules[i].regex, REG_EXTENDED);
    if (ret != 0) {
      regerror(ret, &re[i], error_msg, 128);
      panic("regex compilation failed: %s\n%s", error_msg, rules[i].regex);
    }
  }
}

typedef struct token {
  int type;
  char str[32];
} Token;

static Token tokens[32] __attribute__((used)) = {};
static int nr_token __attribute__((used))  = 0;

static bool make_token(char *e) {
  int position = 0;
  int i;
  regmatch_t pmatch;

  nr_token = 0;

  while (e[position] != '\0') {
    /* Try all rules one by one. */
    for (i = 0; i < NR_REGEX; i ++) {
      if (regexec(&re[i], e + position, 1, &pmatch, 0) == 0 && pmatch.rm_so == 0) {
        char *substr_start = e + position;
        int substr_len = pmatch.rm_eo;

        Log("match rules[%d] = \"%s\" at position %d with len %d: %.*s",
            i, rules[i].regex, position, substr_len, substr_len, substr_start);


        /* TODO: Now a new token is recognized with rules[i]. Add codes
         * to record the token in the array `tokens'. For certain types
         * of tokens, some extra actions should be performed.
         */

        if(nr_token >= 32) {
            printf("Error: Token numbers overflow!\n");
            return false;
        }

        switch (rules[i].token_type) {
          case TK_NOTYPE: break;
          default: tokens[nr_token].type = rules[i].token_type; break;
        }

        substr_len = substr_len >= 32 ? 31 : substr_len;

        position += substr_len;

        strncpy(tokens[nr_token].str, substr_start, substr_len);
        tokens[nr_token].str[substr_len] = '\0';

        nr_token++;

        break;
      }
    }

    if (i == NR_REGEX) {
      printf("no match at position %d\n%s\n%*.s^\n", position, e, position, "");
      return false;
    }
  }

  return true;
}

word_t eval_expression(bool *success);
word_t eval_term(bool *success);
static word_t eval_factor(bool *success);
static word_t eval_register(const char *reg, bool *success);

static int token_idx = 0;

static Token* current_token() {
    if(token_idx >= nr_token) return NULL;
    return &tokens[token_idx];
}

static bool match_token(int expected_type) {
    Token *token = current_token();
    if(token != NULL && token->type == expected_type) {
        token_idx++;
        return true;
    }
    return false;
}

word_t expr(char *e, bool *success) {
  if (!make_token(e)) {
    *success = false;
    return 0;
  }

  /* TODO: Insert codes to evaluate the expression. */
  token_idx = 0;
  word_t result = eval_expression(success);

  if(*success && token_idx != nr_token) {
      printf("Error: never complete\n");
      *success = false;
      return 0;
  }

  return result;
}

word_t eval_expression(bool *success) {
    word_t result = eval_term(success);
    //printf("expr result: 0x%08x, %d\n", result, *success);
    if(!*success) return 0;

    while(1) {
        Token *token = current_token();
        if(token == NULL) break;

        if(token->type == '+') {
            token_idx++;
            word_t right = eval_term(success);
            //printf("expr + right: 0x%08x\n", right);
            if(!*success) return 0;
            result += right;
        } else if (token->type == '-') {
            token_idx++;
            word_t right = eval_term(success);
            if(!*success) return 0;
            result -= right;
        } else break;
    }
    //printf("expr result: 0x%08x\n", result);

    return result;
}

word_t eval_term(bool *success) {
    word_t result = eval_factor(success);
    //printf("term result: 0x%08x, %d\n", result, *success);
    if(!*success) return 0;
    
    while(1) {
        Token *token = current_token();
        if(token == NULL) break;

        if(token->type == '*') {
            token_idx++;
            word_t right = eval_factor(success);
            if(!*success) return 0;
            result *= right;
        } else if(token->type == '/') {
            token_idx++;
            word_t right = eval_factor(success);
            if(!*success) return 0;
            if(right == 0) {
                printf("Error: Divided by zero\n");
                return 0;
            }
            result /= right;
        } else break;
    }

    //printf("term result: 0x%08x\n", result);
    return result;
}

static word_t eval_factor(bool *success) {
    Token *token = current_token();
    if(token == NULL) {
        printf("Error: expected factor\n");
        *success = false;
        return 0;
    }

    *success = true;

    switch(token->type) {
        case TK_NUM:      token_idx++; return (word_t)atoi(token->str); 
        case TK_HEX_NUM:  token_idx++; return (word_t)strtoul(token->str, NULL, 16);
        case TK_REG:      token_idx++; return eval_register(token->str, success);
        case '-':         token_idx++; word_t value = eval_factor(success); if(!*success) return 0; return -value;
        case '(':         token_idx++; word_t result = eval_expression(success); if(!*success) return 0; 
                          if(!match_token(')')) {printf("Error: expected right parenthesis\n"); *success = false; return 0;}
                          return result;
        default:          printf("Error: Could not recognize factor: %s\n", token->str); *success = false; return 0;
    }
}

static word_t eval_register(const char *reg, bool *success) {
    *success = true;

    if(reg[0] == '$') reg++;

    for(int i=0; i<MUXDEF(CONFIG_RVE, 16, 32); i++) {
        if(strcmp(reg, reg_name(i)) == 0) {
            return gpr(i);
        }
    }

    if(strcmp(reg, "pc") == 0) {
        return cpu.pc;
    }

    printf("Error: reg error\n");
    *success = false;
    return 0;
}
