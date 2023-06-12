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

# Statistics of battery history item active time
# Input: Records that have same name
: << ExampleInput
*alarm* com.tencent.android.qqdownloader_KcSdk-Main_action.ka.cy        28914      8h1m54s      1
ExampleInput
# Output: name; total alarm active time in seconds; total alarm counts
function battery_analyze_batteryhistory_summary_activetime() {
    local records="$1"
    local name=`echo -e "$records" | awk 'END{$1="";$2="";$3="";$4="";print $0}' | sed 's/^[ ]*//g; s/[ ]*$//g'`
    local records_timeonly=`echo -e "$records" | sed 's/^[ ]*//g; s/[ ]*$//g' | awk '{print $1" "$2}'`
    unset records

: << Output
*walarm* ScheduleConditionProvider.EVALUATE:
1h36m43s352ms +
1h36m43s372ms -
10h36m43s353ms +
10h36m43s369ms -
Output
    # echo -e "$name:" && echo -e "$records_timeonly"

    local total_activetime=0
    local total_activecount=0
    while read record; do
        local time_formatted=`echo -e "$record" | awk '{print $1}'`
        local action=`echo -e "$record" | awk '{print $2}'`
        local time_in_seconds=`alarm_parse_runtimefield "$time_formatted" | awk '{print $5}'`

        # echo -e "$action $time_formatted $time_in_seconds"

        [ "+" == "$action" ] && \
            let total_activetime+=time_in_seconds ; let total_activecount+=1
        [ "-" == "$action" ] && \
            let total_activetime-=time_in_seconds
    done <<< "$(echo -e "$records_timeonly")"

    local total_activetime_formatted=`time_datetime_fromseconds "$total_activetime" | awk '{print $NF}'`

    echo -e "$name $total_activetime $total_activetime_formatted $total_activecount"
}

# Parse battery history and make alarm summary
# Output: Total alarm in battery history
function battery_analyze_batteryhistory_alarm_summary() {
    local dumpfile="$1"
    # Only time and detail: +12h50m54s334ms +wifi_scan-alarm=u0a124:"*alarm*:com.cctv.yangshipin.app.androidp_KcSdk-Main_action.hb.a.c"
    local batteryhistory_dump=`batterystats_parse_get_batteryhistory_dump "$dumpfile"`
    local batteryhistory_dump_alarm=`echo -e "$batteryhistory_dump" | \
        awk '/alarm=/{printf $1" "; for(i=5; i<=NF; ++i)printf $i;printf "\n"}'`
    unset batteryhistory_dump
    # Output: 43s352ms   +   alarm     1000       *alarm* TIME_TICK
    local batteryhistory_dump_alarm_formatted=`echo -e "$batteryhistory_dump_alarm" | \
        sed -e 's/^+//g; s/ [+-]/ & /g; s/:/ /g; s/=/ /g' | xargs printf "  %-20s%-4s%-28s%-16s%s\n"`
    unset batteryhistory_dump_alarm

    # echo -e "Timeline Aquire/Release Type Uid Name" | xargs printf "  %-20s%-4s%-16s%-16s%s\n"
    # echo -e "$batteryhistory_dump_alarm_formatted"

    # Output: *alarm* TIME_TICK
    local all_names=`echo -e "$batteryhistory_dump_alarm_formatted" | \
        awk '{$1="";$2="";$3="";$4="";print $0}' | \
            sed 's/^[ ]*//g; s/[ ]*$//g' | \
                sort | uniq`
    # echo -e "$all_names"

    echo -e "$all_names" | while read name; do
        local name_no_wildcard=`echo -e "$name" | sed 's/\*/\\\*/g'`
        local records=`echo -e "$batteryhistory_dump_alarm_formatted" | grep -w "$name_no_wildcard"`

: << ExampleOutput
*alarm* android.intent.action.DATE_CHANGED:
  3h36m43s355ms       +   alarm                       1000            *alarm* android.intent.action.DATE_CHANGED
  3h36m44s340ms       -   alarm                       1000            *alarm* android.intent.action.DATE_CHANGED
*alarm* com.android.server.action.NETWORK_STATS_POLL:
  7m56s447ms          +   alarm                       1000            *alarm* com.android.server.action.NETWORK_STATS_POLL
  7m56s505ms          -   alarm                       1000            *alarm* com.android.server.action.NETWORK_STATS_POLL
ExampleOutput
        # echo -e "$name:" && echo -e "$records"

        local total_alarm_active=`battery_analyze_batteryhistory_summary_activetime "$records"`
        echo -e "$total_alarm_active"
    done
}

# Parse battery history and make job summary
# Output: Total job in battery history
function battery_analyze_batteryhistory_job_summary() {
    local dumpfile="$1"
    local batteryhistory_dump=`batterystats_parse_get_batteryhistory_dump "$dumpfile"`
    local batteryhistory_dump_job=`echo -e "$batteryhistory_dump" | \
        awk '/job=/{printf $1" "; for(i=5; i<=NF; ++i)printf $i;printf "\n"}'`
    unset batteryhistory_dump
    local batteryhistory_dump_job_formatted=`echo -e "$batteryhistory_dump_job" | \
        sed -e 's/^+//g; s/ [+-]/ & /g; s/:/ /g; s/=/ /g' | xargs printf "  %-20s%-4s%-28s%-16s%s\n"`
    unset batteryhistory_dump_job

    # 1h12m44s305ms       +   job                         1000            android/com.android.server.pm.DynamicCodeLoggingService
    # echo -e "$batteryhistory_dump_job_formatted"

    local all_names=`echo -e "$batteryhistory_dump_job_formatted" | \
        awk '{$1="";$2="";$3="";$4="";print $0}' | \
            sed 's/^[ ]*//g; s/[ ]*$//g' | \
                sort | uniq`
    # echo -e "$all_names"

    echo -e "$all_names" | while read name; do
        local name_no_wildcard=`echo -e "$name" | sed 's/\*/\\\*/g'`
        local records=`echo -e "$batteryhistory_dump_job_formatted" | grep -w "$name_no_wildcard"`

: << ExampleOutput
android/com.android.server.net.watchlist.ReportWatchlistJobService:
  1h12m44s319ms       +   job                         1000            android/com.android.server.net.watchlist.ReportWatchlistJobService
  1h12m44s331ms       -   job                         1000            android/com.android.server.net.watchlist.ReportWatchlistJobService
android/com.android.server.pm.DynamicCodeLoggingService:
  1h12m44s305ms       +   job                         1000            android/com.android.server.pm.DynamicCodeLoggingService
  1h12m44s528ms       -   job                         1000            android/com.android.server.pm.DynamicCodeLoggingService
ExampleOutput
        # echo -e "$name:" && echo -e "$records"

        local total_job_active=`battery_analyze_batteryhistory_summary_activetime "$records"`
        echo -e "$total_job_active"
    done
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

    local batteryhistory_dump_alarm_summary=`battery_analyze_batteryhistory_alarm_summary "$dumpfile"`

    printf "[  Battery Alarm History:\n"
    local battery_alarm_history=`echo -e "$batteryhistory_dump_alarm_summary" | \
        awk '{count=$NF;time=$(NF-2);time_formatted=$(NF-1);$NF="";$(NF-1)="";$(NF-2)="";printf "%-96s%-12s%-12s%s\n", $0, time, time_formatted, count}'`
    local battery_alarm_history_sorted=`echo -e "$battery_alarm_history" | \
        awk '{print $(NF-1)" "$0}' | sort -rgb | cut -f3- -d' '`
    echo -e "Name Seconds Time Counts" | xargs printf "\t%-88s%-12s%-12s%s\n"
    echo -e "$battery_alarm_history_sorted" | awk '{print "\t", $0}'
    printf "]\n"

    local batteryhistory_dump_job_summary=`battery_analyze_batteryhistory_job_summary "$dumpfile"`

    printf "[  Battery Job History:\n"
    local battery_job_history=`echo -e "$batteryhistory_dump_job_summary" | \
        awk '{count=$NF;time=$(NF-2);time_formatted=$(NF-1);$NF="";$(NF-1)="";$(NF-2)="";printf "%-96s%-12s%-12s%s\n", $0, time, time_formatted, count}'`
    local battery_job_history_sortted=`echo -e "$battery_job_history"`
    echo -e "Name Seconds Time Counts" | xargs printf "\t%-88s%-12s%-12s%s\n"
    echo -e "$battery_job_history_sortted" | awk '{print "\t", $0}'
    printf "]\n"

    printf "+ %.0s" {1..50} ; echo
}

