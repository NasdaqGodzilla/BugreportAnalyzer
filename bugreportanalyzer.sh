#!/bin/bash

export ANALYZER_PATH_BUGREPORT=
export ANALYZER_PATH_DUMPFILE=
export ANALYZER_PATH_OUTPUT=output

export ANALYZER_DUMP_ALARM=
export ANALYZER_DUMP_BATTERY=
export ANALYZER_DUMP_PACKAGE=

source alarm/*
source battery/*
source package/*
source utils/*

ANALYZER_PATH_BUGREPORT="$1"
shift

trap analyzer_exit SIGHUP SIGINT SIGTERM EXIT

function analyzer_info() {
    printf "* %.0s" {1..50}
    echo
    printf "%-32s%-2s%s\n" ANALYZER_PATH_BUGREPORT = "$ANALYZER_PATH_BUGREPORT"
    printf "%-32s%-2s%s\n" ANALYZER_PATH_DUMPFILE = "$ANALYZER_PATH_DUMPFILE"
    printf "* %.0s" {1..50}
    echo
}

function analyzer_exit() {
    local exitcode="$1"
    [ "$exitcode" == "" ] && exitcode=0

    printf "x %.0s" {1..50}
    echo

    trap - SIGHUP SIGINT SIGTERM EXIT

    echo "analyzer_exit"

    [ "$ANALYZER_PATH_DUMPFILE" != "" ] && { \
        echo "Unlinking $ANALYZER_PATH_DUMPFILE"
        unlink "$ANALYZER_PATH_DUMPFILE"
    }

    unset ANALYZER_PATH_BUGREPORT
    unset ANALYZER_PATH_DUMPFILE

    unset ANALYZER_DUMP_ALARM
    unset ANALYZER_DUMP_BATTERY
    unset ANALYZER_DUMP_PACKAGE

    printf "x %.0s" {1..50}
    echo

    wait
    exit "$exitcode"
}

function analyzer_alarm() {
    ANALYZER_DUMP_ALARM=`alarm_getdump "$ANALYZER_PATH_DUMPFILE"`
: << debugprint
    printf "<ALARM>\t\t\t%.0s" {1..4}
    echo
    echo -e "$ANALYZER_DUMP_ALARM"
    printf "<ALARM>\t\t\t%.0s" {1..4}
    echo
debugprint

    ANALYZER_DUMP_ALARM=
}

function analyzer_battery() {
    ANALYZER_DUMP_BATTERY=`batterystats_getdump "$ANALYZER_PATH_DUMPFILE"`
: << debugprint
    printf "<BATTERY>\t\t\t%.0s" {1..4}
    echo
    echo -e "$ANALYZER_DUMP_BATTERY"
    printf "<BATTERY>\t\t\t%.0s" {1..4}
    echo
debugprint

    ANALYZER_DUMP_BATTERY=
}

function analyzer_package() {
    ANALYZER_DUMP_PACKAGE=`package_getdump "$ANALYZER_PATH_DUMPFILE"`
: << debugprint
    printf "<PACKAGE>\t\t\t%.0s" {1..4}
    echo
    echo -e "$ANALYZER_DUMP_PACKAGE"
    printf "<PACKAGE>\t\t\t%.0s" {1..4}
    echo
debugprint

    ANALYZER_DUMP_PACKAGE=
}

[ "$ANALYZER_PATH_BUGREPORT" == "" ] && { \
    echo "Empty bugreport file"
    analyzer_exit 127
}

ANALYZER_PATH_DUMPFILE=`zip_bugreport_extract "$ANALYZER_PATH_BUGREPORT" "$ANALYZER_PATH_OUTPUT"`
[ "$ANALYZER_PATH_DUMPFILE" == "" ] && { \
    echo "Failed to parse bugreport"
    analyzer_exit 126
}

analyzer_info

analyzer_alarm
analyzer_battery
analyzer_package

analyzer_exit

