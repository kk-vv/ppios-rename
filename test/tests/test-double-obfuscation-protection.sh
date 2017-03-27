#!/bin/bash

#Copyright 2016 PreEmptive Solutions, LLC
#See LICENSE.txt for licensing information

targetAppName=BoxSim
thisDirectory="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
testRoot="$(dirname "${thisDirectory}")"
. "${testRoot}/tests/common.sh"


original="${apps}/${targetAppName}"
work="${sandbox}/${targetAppName}"
buildLog="${results}/build.log"
buildDir=build
program="${work}/${buildDir}/Build/Products/Release-iphoneos/${targetAppName}.app/${targetAppName}"


oneTimeSetUp() {
    checkForPPiOSRename
    checkOriginalIsClean
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


TEST "Normal obfuscated build"
run make build
assertSucceeds
run "${PPIOS_RENAME}" --analyze "${program}"
assertSucceeds
run "${PPIOS_RENAME}" --obfuscate-sources
assertSucceeds
run make build
assertSucceeds
run nm "${program}"
verifyFails grep BSClass "${lastRun}"

TEST "Analyzing obfuscated build fails with error (BAOBA)"
run make build
assertSucceeds
run "${PPIOS_RENAME}" --analyze "${program}"
assertSucceeds
run "${PPIOS_RENAME}" --obfuscate-sources
assertSucceeds
run make build
assertSucceeds
run "${PPIOS_RENAME}" --analyze "${program}"
assertFails
verify grep "Error: Analyzing an already obfuscated binary. This will result in an unobfuscated binary. Please see the documentation for details." "${lastRun}"

TEST "Analyzing obfuscated build fails with error (BAOBA), even with few symbols"
run make build
assertSucceeds
run "${PPIOS_RENAME}" --analyze -F '!*' -F BSClassB -x BSClassB -x squaredB "${program}"
assertSucceeds
run "${PPIOS_RENAME}" --obfuscate-sources
assertSucceeds
run make build
assertSucceeds
run "${PPIOS_RENAME}" --analyze -F '!*' -F BSClassB -x BSClassB -x squaredB "${program}"
assertFails
verify grep "Error: Analyzing an already obfuscated binary. This will result in an unobfuscated binary. Please see the documentation for details." "${lastRun}"

TEST "Building double-obfuscated sources yields failing build (BAOAOB)"
verifyFails test -e "${buildDir}"
run make build
assertSucceeds
run "${PPIOS_RENAME}" --analyze "${program}"
assertSucceeds
run "${PPIOS_RENAME}" --obfuscate-sources
assertSucceeds
run "${PPIOS_RENAME}" --analyze "${program}"
assertSucceeds
run "${PPIOS_RENAME}" --obfuscate-sources
assertSucceeds
run make build
assertFails
verify grep "Double obfuscation detected. This will result in an unobfuscated binary. Please see the documentation for details." "${lastRun}"

report
