#!/bin/bash

source package/*

function batterystats_getdump() {
    local dumpfile="$1"

    local line_start=`cat "$dumpfile" | awk '/DUMP OF SERVICE batterystats/{print NR}'`
    local line_end=`cat "$dumpfile" | awk '/duration of dumpsys batterystats/{print NR}'`

    echo batterystats_getdump LINE_START/END: $line_start/$line_end
    sed -n "$line_start,$line_end{p}" "$dumpfile"
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

