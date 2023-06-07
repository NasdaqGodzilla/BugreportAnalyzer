#!/bin/bash

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
  u0a121:     1s 696ms
  u0a119:     20m 52s 971ms
  u0a117:     1s 229ms
  u0a116:     11h 58m 0s 174ms
  1000:     3m 20s 260ms
ExampleOutput
function batterystats_parse_totalwake_actualpartial() {
    local batterystats_raw="$1"

    local totalwakes=`echo -e "$batterystats_raw" | tac | \
        awk '/TOTAL wake:/{print;flag=1}; flag&&/^  [0-9]+:$/{print;flag=0}; flag&&/^  u[0-9]+a[0-9]+:$/{print;flag=0}' | \
        sed -n 'h;n;G;p' | \
        sed -n 'N;s/\n//;p' | \
        awk '/actual partial/{print}'`

    # echo -e Total wakes:"\n""$totalwakes"

    echo -e "$totalwakes" | \
        sed -n '
            ;s/actual partial.*$/actual partial/g
            ;s/TOTAL wake.*,\(.*\)actual partial$/\1/g
            ;p
        '
}

