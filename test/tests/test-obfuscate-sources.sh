#!/bin/bash

#Copyright 2016 PreEmptive Solutions, LLC
#See LICENSE.txt for licensing information

targetAppName=BoxSim
thisDirectory="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
testRoot="$(dirname "${thisDirectory}")"
. "${testRoot}/tests/common.sh"


original="${apps}/${targetAppName}"
prepared="${sandbox}/${targetAppName}-pre"
work="${sandbox}/${targetAppName}"
buildLog="${results}/build.log"
buildDir=build

program="${work}/${appInFolder}"


oneTimeSetUp() {
    checkForPPiOSRename
    checkOriginalIsClean

    rsyncInSandbox -a --delete "${original}/" "${prepared}"

    echo "Building and analyzing ..."
    (
        set -e
        cd "${prepared}"
        make build &> "${buildLog}"
        productsDir="${prepared}/${buildDir}/Build/Products"
        preparedProgram="${productsDir}/Release-iphoneos/${targetAppName}.app/${targetAppName}"
        "${PPIOS_RENAME}" --analyze "${preparedProgram}" >> "${buildLog}" 2>&1
    )
    if test $? -ne 0
    then
        echo "Setup failed" >&2
        exit 1
    fi
    
    echo "Done."
}

oneTimeTearDown() {
    rmFromSandbox "${prepared}"
    rmFromSandbox "${work}"
}

setUp() {
    rsyncInSandbox -a --delete "${prepared}/" "${work}"
    pushd "${work}" > /dev/null
}

tearDown() {
    popd > /dev/null
}


TEST "obfuscate sources works"
run "${PPIOS_RENAME}" --obfuscate-sources
assertSucceeds

TEST "obfuscate sources: option --symbols-header: works"
verifyFails test -f symbolz.h
run "${PPIOS_RENAME}" --obfuscate-sources --symbols-header symbolz.h
assertSucceeds
verify test -f symbolz.h

TEST "obfuscate sources: option --symbols-header: missing argument fails"
run "${PPIOS_RENAME}" --obfuscate-sources --symbols-header
assertFails
assertRunsQuickly

TEST "obfuscate sources: option --symbols-header: empty argument fails"
run "${PPIOS_RENAME}" --obfuscate-sources --symbols-header ''
assertFails
assertRunsQuickly

TEST "obfuscate sources: option --storyboards: works"
originalStoryboards="${targetAppName}/Base.lproj"
originalSums="$(checksum "${originalStoryboards}")"
copiedStoryboards="${targetAppName}/Copied.lproj"
run cp -r "${originalStoryboards}" "${copiedStoryboards}"
verify test "${originalSums}" = "$(checksum "${copiedStoryboards}")"
run "${PPIOS_RENAME}" --obfuscate-sources --storyboards "${copiedStoryboards}"
assertSucceeds
verify test "${originalSums}" = "$(checksum "${originalStoryboards}")"
verifyFails test "${originalSums}" = "$(checksum "${copiedStoryboards}")"

TEST "obfuscate sources: option --storyboards: missing argument fails"
run "${PPIOS_RENAME}" --obfuscate-sources --storyboards
assertFails
assertRunsQuickly

TEST "obfuscate sources: option --storyboards: empty argument fails"
run "${PPIOS_RENAME}" --obfuscate-sources --storyboards ''
assertFails
assertRunsQuickly

TEST "obfuscate sources: option --storyboards: bogus"
run "${PPIOS_RENAME}" --obfuscate-sources --storyboards bogus
assertFails
assertRunsQuickly

report
