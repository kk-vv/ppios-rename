#!/bin/bash

#Copyright 2016-2017 PreEmptive Solutions, LLC
#See LICENSE.txt for licensing information

targetAppName=BoxSim
thisDirectory="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
testRoot="$(dirname "${thisDirectory}")"
. "${testRoot}/tests/common.sh"


original="${apps}/${targetAppName}-support"
work="${sandbox}/${targetAppName}"
buildLog="${results}/build.log"
buildDir=build


oneTimeSetUp() {
    checkForPPiOSRename
}

oneTimeTearDown() {
   rmFromSandbox "${work}"
}

setUp() {
    rsyncInSandbox -a --delete "${original}/" "${work}"
    pushd "${work}" > /dev/null
}

tearDown() {
    popd > /dev/null
}


assertSymbolicatedCrashdump() {
    verifyFails test grep -- '-\[BSClassP doSomethingP:]' "$1"
    verify grep -- '-\[BSClassO doSomethingO:]' "$1" # BSClassO was excluded from renaming
    verifyFails test grep -- '+\[BSClassN doSomethingInClassN:]' "$1"
    verifyFails test grep -- '-\[BSClassM doSomethingM:]' "$1"
    verifyFails test grep -- '-\[ViewController justGoAction:]' "$1"
}

. "${testRoot}/tests/common-assertions.sh"

input=symbolicated.crash
output=de-obfuscated.crash

TEST "translate crashdump works"
originalSum="$(checksum "${input}")"
run "${PPIOS_RENAME}" --translate-crashdump "${input}" "${output}"
assertSucceeds
verify test "${originalSum}" = "$(checksum "${input}")" # no change to original
verify test -f "${output}"
assertSymbolicatedCrashdump "${input}"
assertDeobfuscatedCrashdump "${output}"

TEST "translate crashdump: error handling: symbols-map works"
mv symbols.map symbolz.map
run "${PPIOS_RENAME}" --translate-crashdump "${input}" "${output}"
assertFails
assertRunsQuickly
run "${PPIOS_RENAME}" --translate-crashdump --symbols-map symbolz.map "${input}" "${output}"
assertSucceeds
verify test "${originalSum}" = "$(checksum "${input}")" # no change to original
verify test -f "${output}"
assertSymbolicatedCrashdump "${input}"
assertDeobfuscatedCrashdump "${output}"

TEST "translate crashdump overwriting original works"
originalSum="$(checksum "${input}")"
run "${PPIOS_RENAME}" --translate-crashdump "${input}" "${input}"
assertSucceeds
verifyFails test "${originalSum}" = "$(checksum "${input}")" # original overwritten
assertDeobfuscatedCrashdump "${input}"

TEST "translate crashdump: error handling: no arguments"
run "${PPIOS_RENAME}" --translate-crashdump
assertFails
assertRunsQuickly

TEST "translate crashdump: error handling: only one argument"
run "${PPIOS_RENAME}" --translate-crashdump "${input}"
assertFails
assertRunsQuickly

TEST "translate crashdump: error handling: too many arguments"
run "${PPIOS_RENAME}" --translate-crashdump "${input}" "${output}" bogus
assertFails
assertRunsQuickly

TEST "translate crashdump: error handling: empty input"
run "${PPIOS_RENAME}" --translate-crashdump '' "${output}"
assertFails
assertRunsQuickly

TEST "translate crashdump: error handling: bogus input"
run "${PPIOS_RENAME}" --translate-crashdump bogus "${output}"
assertFails
assertRunsQuickly

TEST "translate crashdump: error handling: empty output"
run "${PPIOS_RENAME}" --translate-crashdump "${input}" ''
assertFails
assertRunsQuickly

TEST "translate crashdump: error handling: symbols-map argument missing"
run "${PPIOS_RENAME}" --translate-crashdump --symbols-map "${input}" "${output}"
assertFails
assertRunsQuickly

TEST "translate crashdump: error handling: symbols-map argument empty"
run "${PPIOS_RENAME}" --translate-crashdump --symbols-map '' "${input}" "${output}"
assertFails
assertRunsQuickly

TEST "translate crashdump: error handling: symbols-map argument bogus"
run "${PPIOS_RENAME}" --translate-crashdump --symbols-map bogus "${input}" "${output}"
assertFails
assertRunsQuickly

#----------------------------------------------
# Test the removed --translate-dsym option.
#----------------------------------------------

TEST "translate dSYM fails"
run "${PPIOS_RENAME}" --translate-dsym
assertFails
assertRunsQuickly
verify grep -- "--translate-dsym functionality has been replaced" "${lastRun}"

report
