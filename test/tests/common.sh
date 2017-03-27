#!/usr/bin/env false
# this script is intended to be sourced by other scripts, not run directly

#Copyright 2016-2017 PreEmptive Solutions, LLC
#See LICENSE.txt for licensing information

# Note: this file is being kept in sync with PPiOS-Rename/test/tests/common.sh

# TEST FRAMEWORK:
#
# Each test script is composed of the following four parts:
# 1. Inclusion of this test framework script and initial configuration
# 2. Per-script and per-test setup and tear down functions
# 3. Test definitions (as sequences of commands)
# 4. The 'report' command
#
# Each test starts with the 'TEST' command followed by the test name, and ends
# when the next test starts or the report command is executed.  After the tests
# have run, the 'report' command prints a summary of the test results.  Commands
# under test are prefixed with the 'run' command, which logs and times the
# command.  Commands verifying assertions are verified with the 'verify'
# command, and similarly for the 'verifyFails' command for negative assertions.
# The 'assertSucceeds' and 'assertFails' commands check the return code from
# command under test with 'run'.
#
# LAYOUT:
#
# tests/ - committed directory containing this, tests scripts, and test-suite.sh
# apps/ - committed directory containing test programs and their resources
# sandbox/ - directory where tests are executed
# results/ - directory containing the test log and output from the last 'run'
#
# DIAGNOSIS:
#
# As a first step, review the contents of the test log ${testRoot}/results
# /test-suite.log.  This will log the 'verify' statements and record the output
# from commands under test (with 'run').  The failing test can be found by
# searching for 'FAIL'.
#
# If the issue with the failed test is not clear by examining the log, comment
# out all test scripts in the test suite (in ${testRoot}/tests/test-suite.sh)
# except for the failing script.  Comment out all of the tests except for the
# failing test.  At this point the failing test can by run by invoking the
# outermost test script which calls ${testRoot}/tests/test-suite.sh.  This
# ensures that the same conditions and environment variables, etc. are used.
#
# After a test script runs, the sandbox (in ${testRoot}/sandbox/) is cleaned up,
# and any intermediate results (which might aid in diagnosis) are removed.
# Comment-out the contents of the 'tearDown' and 'oneTimeTearDown' functions,
# add 'return' (bash doesn't like empty functions), and rerun the outermost
# script.
#
# Further diagnosis can be done by setting up the environment in a shell (with
# 'export VARIABLE=blah'), and running the individual commands in the test.
# It is a good idea to run these commands from the sandbox directory rather than
# from the apps directory, since any changes made in the apps directory will be
# copied over to the sandbox and may affect the results of other tests.  Omit
# the wrapper commands like 'run', 'verify', etc..  The outermost script should
# emit the pertinent enviroment variables with their values.  If there is any
# question about what the environment should look like, just add 'env;exit 1' to
# the top of the test and rerun.  Test lines invoked with 'run' won't have their
# output logged in the same way that they are when the test runs normally.
#
# Theoretically this script could be sourced in a shell and the lines of the
# test script run verbatim, but this is untested.

export PPIOS_RENAME="${PPIOS_RENAME:-ppios-rename}"

if test "${testRoot}" = "" \
        || test "${targetAppName}" = ""
then
    echo "common.sh: error: set targetAppName and testRoot variable to the root of the" >&2
    echo "test directory before sourcing this script.  For example:" >&2
    echo "" >&2
    echo '  targetAppName=BoxSim' >&2
    echo '  thisDirectory="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"' >&2
    echo '  testRoot="$(dirname "${thisDirectory}")"' >&2
    echo '  . "${testRoot}/tests/common.sh"' >&2
    exit 1
fi

sandbox="${testRoot}/sandbox"
apps="${testRoot}/apps"
results="${testRoot}/results"

test -e "${sandbox}" || mkdir -p "${sandbox}"
test -e "${results}" || mkdir -p "${results}"

lastRun="${results}/last.log"
lastResultFile="${results}/last.result"
testLog="${results}/test-suite.log"

shortTimeout=100 # milliseconds

testCount=0
failureCount=0
successCount=0

testName=""
error=""
firstSetup=yes

testSuiteLog() {
    echo "$@" >> "${testLog}"
}

logAndEcho() {
    testSuiteLog "$@"
    echo "$@"
}

# capitalization of these methods mimics that of shunit2
oneTimeSetUp() {
    return 0
}

oneTimeTearDown() {
    return 0
}

setUp() {
    return 0
}

tearDown() {
    return 0
}

finishTest() {
    if test "${testName}" != ""
    then
        tearDown

        if test "${error}" != ""
        then
            logAndEcho "FAIL"
            logAndEcho "  File: '$(basename $0)'"
            logAndEcho "  Error: '${error}'"
            failureCount=$((failureCount + 1))
        else
            logAndEcho "PASS"
            successCount=$((successCount + 1))
        fi

        testSuiteLog "$(date)"

        testName=""
        error=""
    fi
}

TEST() {
    if test "${firstSetup}" = "yes"
    then
        firstSetup=""

        # clears the log
        date > "${testLog}"

        oneTimeSetUp
    else
        # between tests
        finishTest
    fi

    testName="$1"
    testCount=$((testCount + 1))

    testSuiteLog ""
    testSuiteLog "Setup:"

    setUp

    echo -n "Test: ${testName}: "
    testSuiteLog "Test: ${testName}: "
}

report() {
    finishTest

    oneTimeTearDown

    echo "Done."
    echo "Tests run: ${testCount}, pass: ${successCount}, fail: ${failureCount}"

    if test "${testCount}" -eq 0
    then
        echo "error: no tests were executed" >&2
        exit 2
    fi

    if test "${successCount}" -lt "${testCount}" \
            || test "${failureCount}" -gt 0
    then
        exit 1
    fi
}

run() {
    if test "${error}" = ""
    then
        testSuiteLog "$@"

        # time the execution, get the exit code, and record stdout and stderr
        # subshell is necessary to get at the output
        # the awk-bc part splits the output from time and produces a millisecond value
        lastMS=$( (
            time "$@" &> "${lastRun}"
            echo $? > "${lastResultFile}"
        ) 2>&1 \
            | grep real \
            | awk 'BEGIN { FS="[\tms.]" } { printf("(%d * 60 + %d) * 1000 + %d\n", $2, $3, $4); }' \
            | bc)

        lastResult="$(cat "${lastResultFile}")"

        testSuiteLog "$(cat "${lastRun}")"
        testSuiteLog "exit code: ${lastResult}"
        testSuiteLog "run time: ${lastMS} ms"

        # because of the subshell, the result cannot be passed directly in a variable
        return "${lastResult}"
    else
        return 0
    fi
}

verify() {
    if test "${error}" = ""
    then
        # only record if an error has not already happened
        testSuiteLog "verify $@"

        "$@" &> /dev/null
        result=$?
        if test "${result}" -ne 0
        then
            error="\"$@\" (return: ${result})"
        fi
    fi
}

verifyFails() {
    if test "${error}" = ""
    then
        # only record if an error has not already happened
        testSuiteLog "verifyFails $@"

        "$@" &> /dev/null
        result=$?
        if test "${result}" -eq 0
        then
            error="\"$@\" (expected non-zero)"
        fi
    fi
}

toList() {
    if test "${error}" = ""
    then
        if test $# -lt 2
        then
            echo "$(basename $0): toList <symbols.map> <original-symbols.list>" >&2
            exit 1
        fi

        source="$1"
        destination="$2"

        testSuiteLog "Writing ${destination}"
        cat "${source}" | sed 's|[",]||g' | awk '{ print $3; }' | sort | grep -v '^$' > "${destination}"
    fi
}

rsyncInSandbox() {
    if test $# -lt 2
    then
        echo "$(basename $0): rsyncInSandbox [options] <source-spec> <destination>" >&2
        echo "  Review help documentation for rsync." >&2
        exit 1
    fi

    if [[ "${@: -1}" != */sandbox/* ]]
    then
        echo "$(basename $0): rsyncInSandbox: destination must contain 'sandbox' path part" >&2
        echo "  destination: ${@: -1}" >&2
        exit 2
    fi

    rsync "$@"
}

rmFromSandbox() {
    if test $# -ne 1
    then
        echo "$(basename $0): rmFromSandbox <directory>" >&2
        echo "  Only supports removing one directory at a time from the sandbox." >&2
        exit 1
    fi

    if [[ "$1" != */sandbox/* ]]
    then
        echo "$(basename $0): rmFromSandbox: directory must contain 'sandbox' path part" >&2
        echo "  directory: $1" >&2
        exit 2
    fi

    rm -r -- "$1"
}

checkOriginalIsClean() {
    if test "${original}" != "" \
       && test "${buildDir}" != "" \
       && test -e "${original}/${buildDir}"
    then
        echo "Original directory is not clean: ${original}/${buildDir}" >&2
        exit 1
    fi
}

checkForPPiOSRename() {
    type "${PPIOS_RENAME}" &> /dev/null
    if test $? -ne 0
    then
        echo "$(basename $0): cannot find ${PPIOS_RENAME}" >&2
        exit 1
    fi
}

assertSucceeds() {
    verify test $? -eq 0
}

assertFails() {
    verify test $? -ne 0
}

assertRunsQuickly() {
    verify test "${lastMS}" -lt "${shortTimeout}"
}

checksum() {
    if test -f "$1"
    then
        cat "$1" | md5
    else
        ( cd "$1" ; find . -type f -exec md5 "{}" \; )
    fi
}
