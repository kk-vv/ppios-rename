#!/bin/bash

#Copyright 2016-2017 PreEmptive Solutions, LLC
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


oneTimeSetUp() {
    checkForPPiOSRename
    checkOriginalIsClean

    rsyncInSandbox -a --delete "${original}/" "${prepared}"

    echo "Building ..."
    ( cd "${prepared}" ; make build &> "${buildLog}" )
    echo "Done."
}

oneTimeTearDown() {
    rmFromSandbox "${prepared}"
    rmFromSandbox "${work}"
}

setUp() {
    rsyncInSandbox -a --delete "${prepared}/" "${work}"

    targetApp="$(ls -td $(find "${work}/${buildDir}" -name "*.app") | head -1)"
    targetAppName="$(echo "${targetApp}" | sed 's,.*/\([^/]*\)\.app,\1,')"
    program="$(ls -td $(find "${targetApp}" -type f -and -name "${targetAppName}") | head -1)"

    pushd "${work}" > /dev/null
}

tearDown() {
    popd > /dev/null
}

checkVersion() {
    verify grep PreEmptive "${lastRun}"
    verify grep -i version "${lastRun}"
    verify grep '[1-9][0-9]*[.][0-9][0-9]*[.][0-9][0-9]*' "${lastRun}"

    # verify correct version and commit
    verify grep "${NUMERIC_VERSION:-BAD_VERSION}" "${lastRun}"
    verify grep `git rev-parse --short HEAD` "${lastRun}"
}

checkUsage() {
    checkVersion # usage has version information

    verify grep "Usage:" "${lastRun}"
    # major modes
    verify grep -- --analyze "${lastRun}"
    verify grep -- --obfuscate-sources "${lastRun}"
    verify grep -- --translate-crashdump "${lastRun}"
    verifyFails grep -- --translate-dsym "${lastRun}"
    verify grep -- --list-arches "${lastRun}"
    # minor modes
    verify grep -- --version "${lastRun}"
    verify grep -- --help "${lastRun}"
    # options
    verify grep -- --symbols-map "${lastRun}"
    verify grep -- -F "${lastRun}"
    verify grep -- -x "${lastRun}"
    verify grep -- --arch "${lastRun}"
    verify grep -- --sdk-root "${lastRun}"
    verify grep -- --sdk-ios "${lastRun}"
    verify grep -- --framework "${lastRun}"
    verify grep -- --storyboards "${lastRun}"
    verify grep -- --symbols-header "${lastRun}"
}

TEST "analyze works"
run "${PPIOS_RENAME}" --analyze "${program}"
assertSucceeds
toList symbols.map list
verify grep '^methodA$' list
verify test -f symbols.map

TEST "analyze: specifying just the .app works too"
run "${PPIOS_RENAME}" --analyze "${targetApp}"
assertSucceeds
toList symbols.map list
verify grep '^methodA$' list
verify test -f symbols.map

TEST "help works"
run "${PPIOS_RENAME}" -h
assertSucceeds
checkUsage
run "${PPIOS_RENAME}" --help
assertSucceeds
checkUsage

TEST "version works"
run "${PPIOS_RENAME}" --version
assertSucceeds
checkVersion
verify test "$(cat "${lastRun}" | wc -l)" -le 3 # three or fewer lines

TEST "Option -i replaced with -x"
# try old option
run "${PPIOS_RENAME}" --analyze -i methodA "${program}"
assertFails
# try new option
run "${PPIOS_RENAME}" --analyze -x methodA "${program}"
assertSucceeds
toList symbols.map list
verifyFails grep '^methodA$' list

TEST "Option -m replaced with --symbols-map"
# try old option
run "${PPIOS_RENAME}" --analyze -m symbolz.map "${program}"
assertFails
# try new option
verifyFails test -f symbolz.map
run "${PPIOS_RENAME}" --analyze --symbols-map symbolz.map "${program}"
assertSucceeds
verify test -f symbolz.map

TEST "Option -O replaced with --symbols-header"
# try old option
run "${PPIOS_RENAME}" --analyze "${program}"
assertSucceeds
run "${PPIOS_RENAME}" --obfuscate-sources -O symbolz.h
verifyFails test $? -eq 0
# try new option
run "${PPIOS_RENAME}" --obfuscate-sources --symbols-header symbolz.h
verify test $? -eq 0
verify test -f symbolz.h

TEST "Option --emit-excludes writes files"
run "${PPIOS_RENAME}" --analyze --emit-excludes excludes "${program}"
assertSucceeds
verify test -f excludes-classFilters.list
verify test -f excludes-exclusionPatterns.list
verify test -f excludes-forbiddenNames.list

TEST "Change default map file from symbols.json to symbols.map"
verifyFails test -f symbols.json
verifyFails test -f symbols.map
run "${PPIOS_RENAME}" --analyze "${program}"
assertSucceeds
verifyFails test -f symbols.json
verify test -f symbols.map

assertHasInvalidOptionMessage() {
    verify grep 'invalid option' "${lastRun}" # short option form
}

assertHasUnrecognizedOptionMessage() {
    verify grep 'unrecognized option' "${lastRun}" # long option form
}

assertHasFirstArgumentMessage() {
    verify grep 'You must specify the mode of operation as the first argument' "${lastRun}"
}

assertAnalyzeInputFileMessage() {
    verify grep 'Input file must be specified for --analyze' "${lastRun}"
}

TEST "Error handling: no options"
run "${PPIOS_RENAME}"
assertSucceeds
assertRunsQuickly
checkUsage

TEST "Error handling: bad short option"
run "${PPIOS_RENAME}" -q
assertFails
assertRunsQuickly
assertHasInvalidOptionMessage
assertHasFirstArgumentMessage

TEST "Error handling: bad long option"
run "${PPIOS_RENAME}" --bad-long-option
assertFails
assertRunsQuickly
assertHasUnrecognizedOptionMessage
assertHasFirstArgumentMessage

TEST "Error handling: analyze: not enough arguments"
run "${PPIOS_RENAME}" --analyze
assertFails
assertRunsQuickly
assertAnalyzeInputFileMessage

TEST "Error handling: analyze: too many arguments"
run "${PPIOS_RENAME}" --analyze a b
assertFails
assertRunsQuickly

TEST "Error handling: analyze: bad short option"
run "${PPIOS_RENAME}" --analyze -q "${program}"
assertFails
assertRunsQuickly
assertHasInvalidOptionMessage

TEST "Error handling: analyze: bad long option"
run "${PPIOS_RENAME}" --analyze --bad-long-option "${program}"
assertFails
assertRunsQuickly
assertHasUnrecognizedOptionMessage

TEST "Error handling: analyze: options out of order"
run "${PPIOS_RENAME}" -F '!*' --analyze "${program}"
assertFails
assertRunsQuickly
assertHasFirstArgumentMessage

TEST "Error handling: analyze: check that app exists"
run "${PPIOS_RENAME}" --analyze "does not exist"
assertFails
assertRunsQuickly

TEST "Error handling: --analyze: --symbols-map: argument missing"
run "${PPIOS_RENAME}" --analyze --symbols-map "${program}"
assertFails
assertRunsQuickly
# do not specify details of the output

TEST "Error handling: --analyze: --symbols-map: argument empty"
run "${PPIOS_RENAME}" --analyze --symbols-map '' "${program}"
assertFails
assertRunsQuickly

TEST "Error handling: --analyze: -F: argument missing"
run "${PPIOS_RENAME}" --analyze -F "${program}"
assertFails
assertRunsQuickly
# do not specify details of the output

TEST "Error handling: --analyze: -F: argument empty"
run "${PPIOS_RENAME}" --analyze -F '' "${program}"
assertFails
assertRunsQuickly

TEST "Error handling: --analyze: -F: argument malformed"
run "${PPIOS_RENAME}" --analyze -F '!' "${program}"
assertFails
assertRunsQuickly

TEST "Error handling: --analyze: -x: argument missing"
run "${PPIOS_RENAME}" --analyze -x "${program}"
assertFails
assertRunsQuickly
# do not specify details of the output

TEST "Error handling: --analyze: -x: argument empty"
run "${PPIOS_RENAME}" --analyze -x '' "${program}"
assertFails
assertRunsQuickly

TEST "Error handling: --analyze: --arch: argument missing"
run "${PPIOS_RENAME}" --analyze --arch "${program}"
assertFails
assertRunsQuickly
# do not specify details of the output

TEST "Error handling: --analyze: --arch: argument empty"
run "${PPIOS_RENAME}" --analyze --arch '' "${program}"
assertFails
assertRunsQuickly

TEST "Error handling: --analyze: --arch: argument bogus"
run "${PPIOS_RENAME}" --analyze --arch pdp11 "${program}"
assertFails
assertRunsQuickly

TEST "Error handling: --analyze: --sdk-root: argument missing"
run "${PPIOS_RENAME}" --analyze --sdk-root "${program}"
assertFails
assertRunsQuickly
# do not specify details of the output

TEST "Error handling: --analyze: --sdk-root: argument empty"
run "${PPIOS_RENAME}" --analyze --sdk-root '' "${program}"
assertFails
assertRunsQuickly

TEST "Error handling: --analyze: --sdk-root: argument bogus"
run "${PPIOS_RENAME}" --analyze --sdk-root 'does not exist' "${program}"
assertFails
assertRunsQuickly

TEST "Error handling: --analyze: --sdk-ios: argument missing"
run "${PPIOS_RENAME}" --analyze --sdk-ios "${program}"
assertFails
assertRunsQuickly
# do not specify details of the output

TEST "Error handling: --analyze: --sdk-ios: argument empty"
run "${PPIOS_RENAME}" --analyze --sdk-ios '' "${program}"
assertFails
assertRunsQuickly

TEST "Error handling: --analyze: --sdk-ios: argument bogus"
run "${PPIOS_RENAME}" --analyze --sdk-ios bogus "${program}" # expecting: digits ( dot digits ) *
assertFails
assertRunsQuickly

TEST "Error handling: --analyze: --framework: argument missing"
run "${PPIOS_RENAME}" --analyze --framework "${program}"
assertFails
assertRunsQuickly
# do not specify details of the output

TEST "Error handling: --analyze: --framework: argument empty"
run "${PPIOS_RENAME}" --analyze --framework '' "${program}"
assertFails
assertRunsQuickly

TEST "list arches works"
run "${PPIOS_RENAME}" --list-arches "${program}"
assertSucceeds
verify grep armv7 "${lastRun}"
verify grep arm64 "${lastRun}"

TEST "list arches: error handling: not enough arguments"
run "${PPIOS_RENAME}" --list-arches
assertFails
assertRunsQuickly

TEST "list arches: error handling: too many arguments"
run "${PPIOS_RENAME}" --list-arches "${program}" bogus
assertFails
assertRunsQuickly

TEST "Error handling: First argument must not be blank"
run "${PPIOS_RENAME}" --list-arches ''
assertFails
assertRunsQuickly

report
