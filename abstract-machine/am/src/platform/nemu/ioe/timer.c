#include <am.h>
#include <nemu.h>

#define CONFIG_RTC_MMIO 0xa0000048

void __am_timer_init() {
}

void __am_timer_uptime(AM_TIMER_UPTIME_T *uptime) {
    uint32_t time_lo = inw(CONFIG_RTC_MMIO);
    uint32_t time_hi = inw(CONFIG_RTC_MMIO + 4);

    uptime->us = ((uint64_t)time_hi << 32) | time_lo;
}

void __am_timer_rtc(AM_TIMER_RTC_T *rtc) {
    rtc->second = 0;
    rtc->minute = 0;
    rtc->hour   = 0;
    rtc->day    = 0;
    rtc->month  = 0;
    rtc->year   = 1900;
}
