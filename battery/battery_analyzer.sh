#!/bin/bash

export BATTERY_DISCHARGEDCOUNT=
export BATTERY_ELAPSEDTIME_FORMATTED=
export BATTERY_ELAPSEDTIME=
export BATTERY_UPTIME_FORMATTED=
export BATTERY_UPTIME=
export BATTERY_TOTALPARTIAL_FORMATTED=
export BATTERY_TOTALPARTIAL=
export BATTERY_TOTALPARTIAL_ELAPSEDPCT=
export BATTERY_TOTALPARTIAL_UPTIMEPCT=
export BATTERY_RUNNINGPCT=
export BATTERY_DRAINRATE=

export BATTERY_TOTALWAKES=

function battery_analyze() {
    BATTERY_DISCHARGEDCOUNT=`batterystats_parse_powerdischarge "$ANALYZER_DUMP_BATTERY_DISCHARGED"`
    BATTERY_ELAPSEDTIME_FORMATTED=`batterystats_parse_elapsedtime "$ANALYZER_DUMP_BATTERY_STAT"`
    BATTERY_ELAPSEDTIME=`batterystats_parse_elapsedtime_sec "$ANALYZER_DUMP_BATTERY_STAT"`
    BATTERY_UPTIME_FORMATTED=`batterystats_parse_uptime "$ANALYZER_DUMP_BATTERY_STAT"`
    BATTERY_UPTIME=`batterystats_parse_uptime_sec "$ANALYZER_DUMP_BATTERY_STAT"`
    BATTERY_TOTALPARTIAL_FORMATTED=`batterystats_parse_totalpartial "$ANALYZER_DUMP_BATTERY_STAT"`
    BATTERY_TOTALPARTIAL=`batterystats_parse_totalpartial_sec "$ANALYZER_DUMP_BATTERY_STAT"`
    BATTERY_TOTALPARTIAL_ELAPSEDPCT=`batterystats_parse_totalpartial_elapsedpct "$ANALYZER_DUMP_BATTERY_STAT"`
    BATTERY_TOTALPARTIAL_UPTIMEPCT=`batterystats_parse_totalpartial_uptimepct "$ANALYZER_DUMP_BATTERY_STAT"`
    BATTERY_RUNNINGPCT=`batterystats_parse_runningpct "$ANALYZER_DUMP_BATTERY_STAT"`
    BATTERY_DRAINRATE=`batterystats_parse_drainrate "$ANALYZER_DUMP_BATTERY_STAT" "$ANALYZER_DUMP_BATTERY_DISCHARGED"`
    BATTERY_TOTALWAKES=`batterystats_parse_totalwake_actualpartial "$ANALYZER_DUMP_BATTERY_TOTALWAKE" "$ANALYZER_DUMP_PACKAGE"`
}

# Parse battery history and make summary
function battery_analyze_batteryhistory_summary() {
    local dumpfile="$1"
    # Only time and detail: +12h50m54s334ms +wifi_scan-alarm=u0a124:"*alarm*:com.cctv.yangshipin.app.androidp_KcSdk-Main_action.hb.a.c"
    local batteryhistory_dump=`batterystats_parse_get_batteryhistory_dump "$dumpfile"`
    local batteryhistory_dump_alarm=`echo -e "$batteryhistory_dump" | \
        awk '/alarm=/{printf $1" "; for(i=5; i<=NF; ++i)printf $i;printf "\n"}'`
    unset batteryhistory_dump
    local batteryhistory_dump_alarm_formatted=`echo -e "$batteryhistory_dump_alarm" | \
        sed -e 's/^+//g; s/ [+-]/ & /g; s/:/ /g; s/=/ /g' | xargs printf "  %-20s%-4s%-28s%-16s%s\n"`
    unset batteryhistory_dump_alarm

    echo -e "$batteryhistory_dump_alarm_formatted"
}

function battery_analyze_summary() {
    local dumpfile="$1"

    printf "+ %.0s" {1..50} ; echo

    printf "%-32s%-2s%s\n" \
        BATTERY_DISCHARGEDCOUNT = $BATTERY_DISCHARGEDCOUNT
    printf "%-32s%-2s%s\n" \
        BATTERY_ELAPSEDTIME_FORMATTED = $BATTERY_ELAPSEDTIME_FORMATTED
    printf "%-32s%-2s%s\n" \
        BATTERY_ELAPSEDTIME = $BATTERY_ELAPSEDTIME
    printf "%-32s%-2s%s\n" \
        BATTERY_UPTIME_FORMATTED = $BATTERY_UPTIME_FORMATTED
    printf "%-32s%-2s%s\n" \
        BATTERY_UPTIME = $BATTERY_UPTIME
    printf "%-32s%-2s%s\n" \
        BATTERY_TOTALPARTIAL_FORMATTED = $BATTERY_TOTALPARTIAL_FORMATTED
    printf "%-32s%-2s%s\n" \
        BATTERY_TOTALPARTIAL = $BATTERY_TOTALPARTIAL
    printf "%-32s%-2s%s\n" \
        BATTERY_TOTALPARTIAL_ELAPSEDPCT = $BATTERY_TOTALPARTIAL_ELAPSEDPCT
    printf "%-32s%-2s%s\n" \
        BATTERY_TOTALPARTIAL_UPTIMEPCT = $BATTERY_TOTALPARTIAL_UPTIMEPCT
    printf "%-32s%-2s%s\n" \
        BATTERY_RUNNINGPCT = $BATTERY_RUNNINGPCT
    printf "%-32s%-2s%s\n" \
        BATTERY_DRAINRATE = $BATTERY_DRAINRATE

    printf "[  Total Wake:\n"
    echo -e "Package UID Total" | xargs printf "\t%-48s%-8s%s\n"
    echo -e "$BATTERY_TOTALWAKES" | sed 's/|/\t/g' | xargs printf "\t%-48s%-8s%s\n"
    printf "]\n"

    local batteryhistory_dump_alarm_formatted=`battery_analyze_batteryhistory_summary "$dumpfile"`

    printf "[  Battery Alarm History:\n"
    # echo -e "$batteryHistory_dump_alarm"
    echo -e "Timeline Aquire/Release Type Uid Name" | xargs printf "  %-20s%-4s%-16s%-16s%s\n"
    echo -e "$batteryhistory_dump_alarm_formatted"
    printf "]\n"

    printf "+ %.0s" {1..50} ; echo
}

