#!/bin/bash

source package/*
source alarm/*

function batterystats_getdump() {
    local dumpfile="$1"

    local line_start=`cat "$dumpfile" | awk '/DUMP OF SERVICE batterystats/{print NR}'`
    local line_end=`cat "$dumpfile" | awk '/duration of dumpsys batterystats/{print NR}'`

    echo batterystats_getdump LINE_START/END: $line_start/$line_end
    sed -n "$line_start,$line_end{p}" "$dumpfile"
}

# Input: Batterystats dump
# Output: Dump of Discharge step durations
function batterystats_get_powerdischargedump() {
    local batterydump="$1"

    local line_start=`echo -e "$batterydump" | awk '/^Discharge step durations:/{print NR}'`
    local line_end=`echo -e "$batterydump" | awk '/^Daily stats:/{print NR}'`
    let line_start+=1
    let line_end-=2

    # echo batterystats_parse_powerdischarge LINE_START/END: $line_start/$line_end

    local powerdischarge_dump=`echo -e "$batterydump" | sed -n "$line_start,$line_end{p}"`

    # Remove "Estimated screen off|on time"
    powerdischarge_dump=`echo -e "$powerdischarge_dump" | sed '/Estimated screen/d'`

    # Remove prefix whitesapce
    powerdischarge_dump=`echo -e "$powerdischarge_dump" | sed 's/^[ ]*//g'`

    echo -e "$powerdischarge_dump"
}

# Input: Batterystats dump
# Output: Dump of Statistics since last charge
: << ExampleOutput
Statistics since last charge:
System starts: 0, currently on battery: false
Estimated battery capacity: 8000 mAh
Min learned battery capacity: 7924 mAh
Max learned battery capacity: 7924 mAh
Time on battery: 12h 6m 2s 742ms (99.2%) realtime, 12h 6m 2s 739ms (100.0%) uptime
Time on battery screen off: 12h 1m 0s 283ms (99.3%) realtime, 12h 1m 0s 282ms (99.3%) uptime
Time on battery screen doze: 0ms (0.0%)
Total run time: 12h 11m 44s 946ms realtime, 12h 11m 44s 946ms uptime
Discharge: 3804 mAh
Screen off discharge: 3645 mAh
Screen doze discharge: 0 mAh
Screen on discharge: 158 mAh
Device light doze discharge: 3328 mAh
Device deep doze discharge: 0 mAh
Start clock time: 2023-06-05-21-17-09
Screen on: 5m 2s 459ms (0.7%) 1x, Interactive: 5m 2s 32ms (0.7%)
Screen brightnesses:
dark 36ms (0.0%)
light 5m 2s 423ms (100.0%)
Device light idling: 11h 54m 59s 340ms (98.5%) 2x
Idle mode light time: 11h 32m 14s 918ms (95.3%) 38x -- longest 26m 3s 980ms
Total full wakelock time: 2s 126ms
Total partial wakelock time: 11h 58m 0s 620ms
ExampleOutput
function batterystats_get_statisticsdump() {
    local batterydump="$1"

    local line_start=`echo -e "$batterydump" | awk '/^Statistics since last charge:/{print NR}'`
    local line_end=`echo -e "$batterydump" | awk '/Total partial wakelock time:/{print NR}'`

    # echo batterystats_get_statisticsdump LINE_START/END: $line_start/$line_end

    local battery_statisticsdump=`echo -e "$batterydump" | sed -n "$line_start,$line_end{p}"`

    # Remove prefix whitesapce
    battery_statisticsdump=`echo -e "$battery_statisticsdump" | sed 's/^[ ]*//g'`

    echo -e "$battery_statisticsdump"
}

: << ExampleOutput
Total wakes:
  u0a121:    TOTAL wake: 595ms blamed partial, 1s 696ms actual partial, 1s 653ms actual background partial realtime
  u0a119:    TOTAL wake: 13m 47s 765ms blamed partial, 20m 52s 971ms actual partial, 20m 52s 971ms actual background partial realtime
  u0a117:    TOTAL wake: 614ms blamed partial, 1s 229ms actual partial realtime
  u0a116:    TOTAL wake: 11h 42m 40s 491ms blamed partial, 11h 58m 0s 174ms actual partial, 40m 51s 618ms actual background partial realtime
  1000:    TOTAL wake: 511ms full, 1m 29s 633ms blamed partial, 3m 20s 260ms actual partial realtime
  1000: 3m 20s 260ms
  u0a116: 11h 58m 0s 174ms
  u0a117: 1s 229ms
  u0a119: 20m 52s 971ms
  u0a121: 1s 696ms
ExampleOutput
function batterystats_parse_totalwake_actualpartial_() {
    local batterystats_raw="$1"

    local totalwakes=`echo -e "$batterystats_raw" | tac | \
        awk '/TOTAL wake:/{print;flag=1}; flag&&/^  [0-9]+:$/{print;flag=0}; flag&&/^  u[0-9]+a[0-9]+:$/{print;flag=0}' | \
        sed -n 'h;n;G;p' | \
        sed -n 'N;s/\n//;p' | \
        awk '/actual partial/{print}'`

    # echo -e Total wakes:"\n""$totalwakes"

    local total_actual_partial=`echo -e "$totalwakes" | \
        sed -n '
            ;s/actual partial.*$/actual partial/g
            ;s/TOTAL wake.*,\(.*\)actual partial$/\1/g
            ;p
        ' | tr -s [:space:] | sort
    `

    # echo -e Total actual partial:"\n""$total_actual_partial"

    echo -e "$total_actual_partial"
}

# Input: Batterystats dump; Package dump
# Output: App total wake
: << ExampleOutput
android|1000|3m20s260ms
com.tencent.android.qqdownloader|u0a116|11h58m0s174ms
com.baidu.netdisk|u0a117|1s229ms
com.alibaba.android.rimet|u0a119|20m52s971ms
com.tencent.wemeet.app|u0a121|1s696ms
ExampleOutput
function batterystats_parse_totalwake_actualpartial() {
    local batterydump="$1"
    local packagedump="$2"

    local totalwake_without_pkgname=`batterystats_parse_totalwake_actualpartial_ "$batterydump"`
    local package_summary=`package_get_pkgsummary "$packagedump"`

    # echo -e "$totalwake_without_pkgname" "$package_summary"

    # Remove white-space
    totalwake_without_pkgname=`echo -e "$totalwake_without_pkgname" | sed -e 's/[ ]*//g'`
    # echo -e "$totalwake_without_pkgname"

    local all_uids=`echo -e "$totalwake_without_pkgname" | awk -F: '{print $1}'`
    local all_packages=
    local totalwakes=
    for totalwake_raw in `echo -e "$totalwake_without_pkgname"`; do
        local uid_formatted=`echo -e "$totalwake_raw" | awk -F: '{print $1}' | sed -e 's/[ ]*//g'`
        local uid=`package_get_uidint "$uid_formatted"`
        local pkgname=`package_get_pkgname "$package_summary" "$uid_formatted" | head -n1`
        # echo -e "$uid_formatted $uid $pkgname"
        all_packages="$all_packages\n$pkgname"
        totalwakes="$totalwakes\n$pkgname $totalwake_raw"
    done

    totalwakes=`echo -e "$totalwakes" | sed -e 's/[ :]/|/g'`

    # echo -e "$all_uids\n$all_packages\n$totalwake_without_pkgname\n$totalwakes"

    echo -e "$totalwakes"
}

# Input: Batterystats dump
# Output: Total discharge count
function batterystats_parse_powerdischarge() {
    local batterydump="$1"
    local powerdischarge_dump=`batterystats_get_powerdischargedump "$batterydump"`

    # echo -e "$powerdischarge_dump"

    local discharge_step_startlevel=`echo -e "$powerdischarge_dump" | awk '{level=$4}END{print level}'`
    local discharge_step_endlevel=`echo -e "$powerdischarge_dump" | awk 'NR==1{print $4}'`
    local discharge_step_discharged=
    let discharge_step_discharged=discharge_step_startlevel-discharge_step_endlevel

    # echo -e "Discharge step start/end: $discharge_step_startlevel-$discharge_step_endlevel=$discharge_step_discharged"

    echo -e "$discharge_step_discharged"
}

# Input: Batterystats dump
# Output: Elapsed time since boot, like 12h6m2s742ms
function batterystats_parse_elapsedtime() {
    local batterydump="$1"
    local batterystats_dump=`batterystats_get_statisticsdump "$batterydump"`

    # echo -e "$batterystats_dump"

    local time_on_battery_realtime=`echo -e "$batterystats_dump" | \
        grep "^Time on battery:" | \
            sed -e 's/^Time on battery: \(.*\) (.*realtime.*/\1/g'
    `

    # Remove white-space
    time_on_battery_realtime=`echo -e "$time_on_battery_realtime" | sed -e 's/[ ]//g'`

    echo -e "$time_on_battery_realtime"
}

# Input: Batterystats dump
# Output: Uptime since boot, like 12h6m2s739ms
function batterystats_parse_uptime() {
    local batterydump="$1"
    local batterystats_dump=`batterystats_get_statisticsdump "$batterydump"`

    # echo -e "$batterystats_dump"

    local time_on_battery_uptime=`echo -e "$batterystats_dump" | \
        grep "^Time on battery:" | \
            sed -e 's/^.*realtime, \(.*\) (.*/\1/g'
    `

    # Remove white-space
    time_on_battery_uptime=`echo -e "$time_on_battery_uptime" | sed -e 's/[ ]//g'`

    echo -e "$time_on_battery_uptime"
}

# See batterystats_parse_elapsedtime, but translate into seconds
function batterystats_parse_elapsedtime_sec() {
    local batterydump="$1"

    local elapsed_time_formatted=`batterystats_parse_elapsedtime "$batterydump"`
    local elapsed_time_sec=`alarm_parse_runtimefield "$elapsed_time_formatted" | awk -F' ' 'END{print $NF}'`

    # echo -e Elapsed: "$elapsed_time_formatted -> $elapsed_time_sec"

    echo -e "$elapsed_time_sec"
}

# See batterystats_parse_uptime, but translate into seconds
function batterystats_parse_uptime_sec() {
    local batterydump="$1"

    local uptime_formatted=`batterystats_parse_uptime "$batterydump"`
    local uptime_sec=`alarm_parse_runtimefield "$uptime_formatted" | awk -F' ' 'END{print $NF}'`

    # echo -e Uptime: "$uptime_formatted -> $uptime_sec"

    echo -e "$uptime_sec"
}

# Calculate CPU running percentage
# Input: Batterystats dump
# Output: Percentage value, like 25
function batterystats_parse_runningpct() {
    local batterydump="$1"

    local elapsed_time_sec=`batterystats_parse_elapsedtime_sec "$batterydump"`
    local uptime_sec=`batterystats_parse_uptime_sec "$batterydump"`
    local pct=
    let pct=uptime_sec*100/elapsed_time_sec

    # echo -e "batterystats_parse_runningpct: uptime_sec/elapsed_time_sec=$uptime_sec/$elapsed_time_sec=$pct"

    echo -e "$pct"
}

# Input: Batterystats dump
# Output: Formatted total partial wakelock time, like 
function batterystats_parse_totalpartial() {
    local batterydump="$1"
    local batterystats_dump=`batterystats_get_statisticsdump "$batterydump"`

    # echo -e "$batterystats_dump"

    local time_totalpartial=`echo -e "$batterystats_dump" | \
        grep "^Total partial wakelock time:" | \
            awk -F: '{print $2}'
    `

    # Remove white-space
    time_totalpartial=`echo -e "$time_totalpartial" | sed -e 's/[ ]//g'`

    echo -e "$time_totalpartial"
}

# See batterystats_parse_totalpartial, but translate into seconds
function batterystats_parse_totalpartial_sec() {
    local batterydump="$1"

    local time_totalpartial=`batterystats_parse_totalpartial "$batterydump"`
    local total_partial_sec=`alarm_parse_runtimefield "$time_totalpartial" | awk -F' ' 'END{print $NF}'`

    # echo -e Total partial: "$time_totalpartial -> $total_partial_sec"

    echo -e "$total_partial_sec"
}

# Percentage of total partial to elapsed time
# Input: Batterystats dump
function batterystats_parse_totalpartial_elapsedpct() {
    local batterydump="$1"

    local elapsed_time_sec=`batterystats_parse_elapsedtime_sec "$batterydump"`
    local totalpartial_sec=`batterystats_parse_totalpartial_sec "$batterydump"`
    local pct=
    let pct=totalpartial_sec*100/elapsed_time_sec

    # echo -e "batterystats_parse_totalpartial_elapsedpct: totalpartial_sec/elapsed_time_sec=$totalpartial_sec/$elapsed_time_sec=$pct"

    echo -e "$pct"
}

# Percentage of total partial to uptime
# Input: Batterystats dump
function batterystats_parse_totalpartial_uptimepct() {
    local batterydump="$1"

    local uptime_sec=`batterystats_parse_uptime_sec "$batterydump"`
    local totalpartial_sec=`batterystats_parse_totalpartial_sec "$batterydump"`
    local pct=
    let pct=totalpartial_sec*100/uptime_sec

    # echo -e "batterystats_parse_totalpartial_uptimepct: totalpartial_sec/uptime_sec=$totalpartial_sec/$uptime_sec=$pct"

    echo -e "$pct"
}

