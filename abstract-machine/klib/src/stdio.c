#include <am.h>
#include <klib.h>
#include <klib-macros.h>
#include <stdarg.h>

#if !defined(__ISA_NATIVE__) || defined(__NATIVE_USE_KLIB__)

#define STRLEN 1024

char *print_int_to_buf(char *out, int num);
char *print_uint_to_buf(char *out, unsigned int num);
char *print_str_to_buf(char *out, char *str); 
int sprintf(char *out, const char *fmt, ...);

int printf(const char *fmt, ...) {
    va_list ap;
    char out[STRLEN];

    va_start(ap, fmt);
    int ret = sprintf(out, fmt, ap);
    va_end(ap);

    putstr(out);

    return ret;
}

int vsprintf(char *out, const char *fmt, va_list ap) {
  panic("Not implemented");
}

int sprintf(char *out, const char *fmt, ...) {
    va_list ap;
    char *origin_out = out; 

    va_start(ap, fmt);

    while(*fmt) {
        if(*fmt == '%') {
            fmt++;
            switch (*fmt) {
                case 'u': {
                    unsigned int num = va_arg(ap, unsigned int);
                    out = print_uint_to_buf(out, num);
                    break;
                }
                case 'd': {
                    int num = va_arg(ap, int);
                    out = print_int_to_buf(out, num);
                    break;
                }
                case 's': {
                    char *str = va_arg(ap, char *);
                    out = print_str_to_buf(out, str);
                    break;
                }
                case 'c': {
                    int ch = va_arg(ap, int);
                    *out++ = (char)ch;
                    break;
                }
                default: {
                    *out++ = '%';
                    *out++ = *fmt;
                    break;
                }
            }
        } else {
            *out++ = *fmt;
        }
        fmt++;
    }

    *out = '\0';
    va_end(ap);

    return out - origin_out;
}

int snprintf(char *out, size_t n, const char *fmt, ...) {
  panic("Not implemented");
}

int vsnprintf(char *out, size_t n, const char *fmt, va_list ap) {
  panic("Not implemented");
}

char *print_uint_to_buf(char *out, unsigned int num) {
    char buffer[32];
    int i = 0;

    if(num == 0) {
        buffer[i++] = '0';
    } else {
        while(num > 0) {
            buffer[i++] = '0' + (num % 10);
            num /= 10;
        }
    }

    for(int j=i-1; j>=0; j--) *out++ = buffer[j];

    return out;
}

char *print_int_to_buf(char *out, int num) {
    char buffer[32];
    int i = 0;
    int is_neg = 0;
    
    if(num < 0) {
        is_neg = 1;
        num = -num;
    }

    if(num == 0) {
        buffer[i++] = '0';
    } else {
        while(num > 0) {
            buffer[i++] = '0' + (num % 10);
            num /= 10;
        }
    }

    if(is_neg) *out++ = '-';

    for(int j=i-1; j>=0; j--) *out++ = buffer[j];

    return out;
}

char *print_str_to_buf(char *out, char *str) {
    while(*str) *out++ = *str++;

    return out;
}

#endif
