#!/bin/bash

export REPORTER_RESULT=

function reporter_get_testcase() {
    cat "$ANALYZER_PATH_TESTCASE"
}

# Output: PASS or FAILED, decided on bugreport and testcase, with messages printing
function reporter_get_result_full() {
    local testcase=`reporter_get_testcase`
    local failed_items=`reporter_get_resultitem_failed "$testcase"`
    local result=`reporter_get_result "$failed_items"`

    printf "^ %.0s" {1..50} ; echo
    echo "Test Result: [$result]"

    [ "" != "$failed_items" ] && { \
        echo -e "\tFailed item(s):"
        echo -e "Item Target/Current" | xargs printf "\t\t%-32s%s%s\n"
        echo -e "$failed_items" | xargs printf "\t\t%-32s %s/%s[failed]\n"
    }

    echo -e "\tTest case:"
    echo -e "Item Target" | xargs printf "\t\t%-32s%s\n"
    echo -e "$testcase" | sed -e 's/:/ <= /g' | xargs printf "\t\t%-32s%s %s\n"
    printf "^ %.0s" {1..50} ; echo
}

# Get failed item if exists
function reporter_get_resultitem_failed() {
    local testcase="$1"
    local failed_items=

    for case in `echo -e "$testcase"`; do
        local name=`echo "$case" | awk -F: '{print $1}'`
        local target=`echo "$case" | awk -F: '{print $2}'`
        local echo_current=`printf 'echo $%s' "$name"`
        local current=`eval "$echo_current"`

        local item=`echo -e "$name $target $current" | \
            awk '$3 > $2 {print}'`

        [ "" != "$item" ] && failed_items="$failed_items\n$item"
    done

    echo -e "$failed_items" | sed -e '/^[[:space:]]*$/d'
}

# Output: "PASS" or "FAILED"
function reporter_get_result() {
    local failed_items="$1"
    [ "" == "$failed_items" ] && { \
        echo PASS
    } || { \
        echo FAILED
    }
}

