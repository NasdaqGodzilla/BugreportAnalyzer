#!/bin/bash

function package_getdump() {
    local dumpfile="$1"

    local line_start=`cat "$dumpfile" | awk '/DUMP OF SERVICE package:/{print NR}'`
    local line_end=`cat "$dumpfile" | awk '/duration of dumpsys package,/{print NR}'`

    echo package_getdump LINE_START/END: $line_start/$line_end
    sed -n "$line_start,$line_end{p}" "$dumpfile"
}

# Input: Formatted uid, like u0a116
# Output: raw id, like 10116
function package_get_uidint() {
    local uid_formatted="$1"

    local userid=`echo -e "$uid_formatted" | sed 's/u\([0-9]*\)a[0-9]*/\1/g'`
    local appid=`echo -e "$uid_formatted" | sed 's/u[0-9]*a\([0-9]*\)$/\1/g'`

    # echo package_get_uidint\("$uid_formatted"\): User/App: $userid/$appid

    local id=
    let id=(userid+1)*10000+appid
    echo $id
}

function package_get_pkgsummary() {
    local dump="$1"

    # Cut raw dump to get area of "Packages"
    local line_start=`echo -e "$dump" | awk '/^Packages:$/{print NR}'`
    local line_end=`echo -e "$dump" | awk '/^Shared users:$/{print NR}'`
    local dump_pkgonly=`echo -e "$dump" | awk -v line_start="$line_start" -v line_end="$line_end" 'NR>line_start && NR<line_end'`

    # echo -e package_get_pkgsummary dump_pkgonly line_start/line_end: $line_start/$line_end "\n""$dump_pkgonly"

    # 1.1: Find Package
    # 1.2: Read userId
    # 1.3: Read versionName, and then concat above lines into one line
    # 2: Remove redundant white space, unuseable fields
    #       from "Package [com.tencent.android.qqdownloader] (e2c299d):     userId=10116     versionName=8.4.3"
    #       to "com.tencent.android.qqdownloader 10116 8.4.3"
    echo -e "$dump_pkgonly" | \
        sed -n '
            /^[ ]*Package \[.*\].*:$/h
            ;/^[ ]*userId=[0-9]*$/H
            ;/^[ ]*versionName=[0-9.]*$/{H;x;{s/\n/ /g};p}
        ' | \
            sed -n '
                s/Package \[//g
                ;s/\] (.*)://g
                ;s/userId=//g
                ;s/versionName=//g
                ;p
            ' | tr -s [:space:] | sort
}

