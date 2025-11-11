#include <am.h>
#include <nemu.h>
#include <stdio.h>

void __am_timer_init() {
}

void __am_timer_uptime(AM_TIMER_UPTIME_T *uptime) {
    uint32_t time_lo = inw(RTC_ADDR);
    printf("%x\n", time_lo);
    uint32_t time_hi = inw(RTC_ADDR+ 4);

    uptime->us = ((uint64_t)time_hi << 32) | (uint64_t)time_lo;
}

void __am_timer_rtc(AM_TIMER_RTC_T *rtc) {
    rtc->second = 0;
    rtc->minute = 0;
    rtc->hour   = 0;
    rtc->day    = 0;
    rtc->month  = 0;
    rtc->year   = 1900;
}
