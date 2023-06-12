#!/bin/bash

# Input: numberic value of time in seconds, NO MILLISECONDS
# Output: Datetime, like 5d8h0m
: << ExampleOutput
source utils/time_utils.sh ;time_datetime_fromseconds 289999
3 8 33 19 3d8h33m19s
source utils/time_utils.sh ;time_datetime_fromseconds 28999
0 8 3 19 8h3m19s
source utils/time_utils.sh ;time_datetime_fromseconds 2899
0 0 48 19 48m19s
source utils/time_utils.sh ;time_datetime_fromseconds 289
0 0 4 49 4m49s
source utils/time_utils.sh ;time_datetime_fromseconds 0
0 0 0 0 0
ExampleOutput
function time_datetime_fromseconds() {
    local time_in_seconds="$1"

    local day=`echo $time_in_seconds/86400 | bc`
    local hour=`echo $time_in_seconds%86400/3600 | bc`
    local min=`echo $time_in_seconds%86400%3600/60 | bc`
    local sec=`echo $time_in_seconds%86400%3600%60 | bc`

    local dhms=( "$day" "$hour" "$min" "$sec" )
    local unit=( "d" "h" "m" "s" )
    local formatted=
    for i in `seq -s' ' 0 3`; do
        local value="${dhms[$i]}"
        local value_unit="${unit[$i]}"
        [ "$value" -gt "0" ] && formatted="$formatted$value$value_unit"
    done

    [ "$formatted" == "" ] && formatted=0

    echo -e "$day $hour $min $sec $formatted"
}

