#!/bin/bash

export ALARM_RUNTIME_STARTS_RAW=
export ALARM_RUNTIME_ELPASED_RAW=
export ALARM_RUNTIME_ELPASED_SECOND=
export ALARM_RUNTIME_UPTIME_RAW=
export ALARM_RUNTIME_UPTIME_SECOND=
export ALARM_RUNTIME_SLEEP_SECOND=
export ALARM_RUNTIME_SLEEP_PCT=

function alarm_getdump() {
    local dumpfile="$1"

    local line_start=`cat "$dumpfile" | awk '/DUMP OF SERVICE alarm/{print NR}'`
    local line_end=`cat "$dumpfile" | awk '/duration of dumpsys alarm/{print NR}'`

    # echo alarm_getdump LINE_START/END: $line_start/$line_end

    sed -n "$line_start,$line_end{p}" "$dumpfile"
}

: << ExampleOutput
 App Alarm history:
    com.android.providers.calendar,                 u0:     -12h49m32s19ms,
    com.sohu.inputmethod.sogouoem,                  u0:     -49m33s999ms,
    com.akax.haofangfa,                             u0:     -3h49m34s323ms,
ExampleOutput
function alarm_get_appalarmhistory_dump() {
    local dumpfile="$1"
    local pkg_summary="$2"

    local line_start=`cat "$dumpfile" | awk '/App Alarm history:/{print NR}'`
    local line_end=`cat "$dumpfile" | awk '/Past-due non-wakeup alarms:/{print NR}'`
    let line_start+=1
    let line_end-=2

    # echo alarm_get_appalarmhistory_dump LINE_START/END: $line_start/$line_end

    local output_raw=`sed -n "$line_start,$line_end{p}" "$dumpfile" | sed 's/[,:-]/ /g'`

    # echo -e "$output_raw"

    local all_packages=`echo -e "$output_raw" | awk '{print $1}'`
    local output=
    for package in `echo -e "$all_packages"`; do
        local uid=`package_get_pkguidint "$pkg_summary" "$package"`
        local line=`echo -e "$output_raw" | grep "$package" | awk -vuid="$uid" '{print $1" "uid" "$3}'`
        output="$output$line\n"
    done

    echo -e "$output"
}

function alarm_parse_runtimefield() {
    local timeraw="$1"

    local fields=`echo -e "$timeraw" | tr "[+dhms]" '\n' | tac | tr '\n' ' '`
    local days=`echo -e "$fields" | awk -F' ' '{print $5}'`
    local hours=`echo -e "$fields" | awk -F' ' '{print $4}'`
    local mins=`echo -e "$fields" | awk -F' ' '{print $3}'`
    local secs=`echo -e "$fields" | awk -F' ' '{print $2}'`
    [[ ! -z "$days" ]] || days=0
    [[ ! -z "$hours" ]] || hours=0
    [[ ! -z "$mins" ]] || mins=0
    [[ ! -z "$secs" ]] || secs=0
    local sum_insecs=
    let sum_insecs=days*60*60*24+hours*60*60+mins*60+secs

    echo -e "$days $hours $mins $secs $sum_insecs"
}

function alarm_parse_runtime() {
    local dump="$1"

    ALARM_RUNTIME_STARTS_RAW=`echo -e "$dump" | awk -F= '/RuntimeStarted/{print $2}'`
    ALARM_RUNTIME_ELPASED_RAW=`echo -e "$dump" | awk -F: '/Runtime uptime \(elapsed\)/{print $2}'`
    ALARM_RUNTIME_UPTIME_RAW=`echo -e "$dump" | awk -F: '/Runtime uptime \(uptime\)/{print $2}'`
    echo Dump of Alarm runtime: $ALARM_RUNTIME_STARTS_RAW $ALARM_RUNTIME_ELPASED_RAW $ALARM_RUNTIME_UPTIME_RAW

    local elapsed_fields=`alarm_parse_runtimefield "$ALARM_RUNTIME_ELPASED_RAW"`
    local elapsed_days=`echo -e "$elapsed_fields" | awk -F' ' '{print $1}'`
    local elapsed_hours=`echo -e "$elapsed_fields" | awk -F' ' '{print $2}'`
    local elapsed_mins=`echo -e "$elapsed_fields" | awk -F' ' '{print $3}'`
    local elapsed_secs=`echo -e "$elapsed_fields" | awk -F' ' '{print $4}'`
    ALARM_RUNTIME_ELPASED_SECOND=`echo -e "$elapsed_fields" | awk -F' ' '{print $5}'`
    echo Elpased Days/Hours/Mins/Secs/SumInSecs: $elapsed_days $elapsed_hours $elapsed_mins $elapsed_secs $ALARM_RUNTIME_ELPASED_SECOND

    local uptime_fields=`alarm_parse_runtimefield "$ALARM_RUNTIME_UPTIME_RAW"`
    local uptime_days=`echo -e "$uptime_fields" | awk -F' ' '{print $1}'`
    local uptime_hours=`echo -e "$uptime_fields" | awk -F' ' '{print $2}'`
    local uptime_mins=`echo -e "$uptime_fields" | awk -F' ' '{print $3}'`
    local uptime_secs=`echo -e "$uptime_fields" | awk -F' ' '{print $4}'`
    ALARM_RUNTIME_UPTIME_SECOND=`echo -e "$uptime_fields" | awk -F' ' '{print $5}'`
    echo Uptime Days/Hours/Mins/Secs/SumInSecs: $uptime_days $uptime_hours $uptime_mins $uptime_secs $ALARM_RUNTIME_UPTIME_SECOND

    let ALARM_RUNTIME_SLEEP_SECOND=ALARM_RUNTIME_ELPASED_SECOND-ALARM_RUNTIME_UPTIME_SECOND
    let ALARM_RUNTIME_SLEEP_PCT=ALARM_RUNTIME_SLEEP_SECOND*100/ALARM_RUNTIME_ELPASED_SECOND

    echo Idle Seconds/Percentage: $ALARM_RUNTIME_SLEEP_SECOND/$ALARM_RUNTIME_SLEEP_PCT%
}

function alarm_analyze_summary() {
    local dumpfile="$1"
    local pkg_summary="$2"
    local app_alarm_history_dump=`alarm_get_appalarmhistory_dump "$dumpfile" "$pkg_summary"`

    printf "+ %.0s" {1..50} ; echo

    printf "[  App Alarm history:\n"
    echo -e "Package UID Total" | xargs printf "\t%-48s%-8s%s\n"
    echo -e "$app_alarm_history_dump" | xargs printf "\t%-48s%-8s%s\n"
    printf "]\n"

    printf "+ %.0s" {1..50} ; echo
}

