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


TEST "Baseline verifying project symbols are renamed"
run "${PPIOS_RENAME}" --analyze "${program}"
toList symbols.map list
#verify grep 'Ignoring @protocol __ARCLiteKeyedSubscripting__' "${lastRun}"
verify grep '^MoreTrimmable$' list
verify grep '^trimEvenMore$' list
for each in A B C D E F G I J # H is a protocol
do
    verify grep 'Adding @class BSClass'"${each}" "${lastRun}"
    verify grep '^BSClass'"${each}"'$' list
    verify grep '^method'"${each}"'$' list
    verify grep '^_squared'"${each}"'$' list
done
verifyFails grep '^[.]cxx_destruct$' list
verify grep 'Adding @category NSString+MoreTrimmable' "${lastRun}"
verify grep 'Ignoring @protocol NSObject' "${lastRun}"
verify grep 'Ignoring @protocol UIApplicationDelegate' "${lastRun}"

TEST "globbing negative filter"
run "${PPIOS_RENAME}" --analyze -F '!BS*' "${program}"
toList symbols.map list
verify grep 'Ignoring @class BSClassA' "${lastRun}"
verifyFails grep '^BSClassA$' list
verifyFails grep '^methodA$' list
verifyFails grep '^_squaredA$' list
verify grep 'Ignoring @class BSClassC' "${lastRun}"
verifyFails grep '^BSClassC$' list
verifyFails grep '^methodC$' list
verifyFails grep '^_squaredC$' list

TEST "globbing negative filter with positive filter"
run "${PPIOS_RENAME}" --analyze -F '!BS*' -F BSClassC "${program}"
toList symbols.map list
verify grep 'Ignoring @class BSClassA' "${lastRun}"
verifyFails grep '^BSClassA$' list
verifyFails grep '^methodA$' list
verifyFails grep '^_squaredA$' list
verify grep 'Adding @class BSClassC' "${lastRun}"
verify grep '^BSClassC$' list
verify grep '^methodC$' list
verify grep '^_squaredC$' list

TEST "globbing negative filter with positive filter but -x wins"
run "${PPIOS_RENAME}" --analyze -F '!BS*' -F BSClassC -x BSClassC "${program}"
toList symbols.map list
verify grep 'Ignoring @class BSClassA' "${lastRun}"
verifyFails grep '^BSClassA$' list
verifyFails grep '^methodA$' list
verifyFails grep '^_squaredA$' list
# Adding or Ignoring "BSClassC" in this case is misleading
verifyFails grep '^BSClassC$' list
verify grep '^methodC$' list
verify grep '^_squaredC$' list

TEST "positive filter before any negative filters produces warning"
run "${PPIOS_RENAME}" --analyze -F BSClassC -F '!BS*' "${program}"
verify grep "Warning: include filters without a preceding exclude filter have no effect" "${lastRun}"

TEST "-F works on categories"
run "${PPIOS_RENAME}" --analyze -F '!MoreTrimmable' "${program}"
verify grep 'Ignoring @category NSString+MoreTrimmable' "${lastRun}"
toList symbols.map list
verifyFails grep '^MoreTrimmable$' list
verifyFails grep '^trimEvenMore$' list

TEST "-F exclusion does not propagate by property type"
run "${PPIOS_RENAME}" --analyze -F '!BSClassA' "${program}"
toList symbols.map list
verify grep 'Ignoring @class BSClassA' "${lastRun}"
verifyFails grep '^BSClassA$' list
verifyFails grep '^methodA$' list
verifyFails grep '^_squaredA$' list
verify grep 'Adding @class BSClassB' "${lastRun}"
verify grep '^BSClassB$' list
verify grep '^methodB$' list
verify grep '^_squaredB$' list

TEST "-F exclusion does not propagate by method return type"
run "${PPIOS_RENAME}" --analyze -F '!BSClassC' "${program}"
toList symbols.map list
verify grep 'Ignoring @class BSClassC' "${lastRun}"
verifyFails grep '^BSClassC$' list
verifyFails grep '^methodC$' list
verifyFails grep '^_squaredC$' list
verify grep 'Adding @class BSClassD' "${lastRun}"
verify grep '^BSClassD$' list
verify grep '^methodD$' list
verify grep '^_squaredD$' list

TEST "-F exclusion does not propagate by method parameter type"
run "${PPIOS_RENAME}" --analyze -F '!BSClassE' "${program}"
toList symbols.map list
verify grep 'Ignoring @class BSClassE' "${lastRun}"
verifyFails grep '^BSClassE$' list
verifyFails grep '^methodE$' list
verifyFails grep '^_squaredE$' list
verify grep 'Adding @class BSClassF' "${lastRun}"
verify grep '^BSClassF$' list
verify grep '^methodF$' list
verify grep '^_squaredF$' list

TEST "-F exclusion does not propagate by protocol in property type"
run "${PPIOS_RENAME}" --analyze -F '!BSClassG' "${program}"
toList symbols.map list
verify grep 'Ignoring @class BSClassG' "${lastRun}"
verifyFails grep '^BSClassG$' list
verifyFails grep '^methodG$' list
verifyFails grep '^_squaredG$' list
verify grep 'Adding @protocol BSClassH' "${lastRun}"
verify grep '^BSClassH$' list

TEST "-F exclusion does not propagate by subclassing"
run "${PPIOS_RENAME}" --analyze -F '!BSClassI' "${program}"
toList symbols.map list
verify grep 'Ignoring @class BSClassI' "${lastRun}"
verifyFails grep '^BSClassI$' list
verifyFails grep '^methodI$' list
verifyFails grep '^_squaredI$' list
verify grep 'Adding @class BSClassJ' "${lastRun}"
verify grep '^BSClassJ$' list
verify grep '^methodJ$' list
verify grep '^_squaredJ$' list

TEST "Excluding a class with -x does not include its contents"
run "${PPIOS_RENAME}" --analyze -x BSClassA "${program}"
toList symbols.map list
verifyFails grep '^BSClassA$' list
verify grep '^methodA$' list
verify grep '^_squaredA$' list

TEST "Excluding a protocol with -x does not include its contents"
run "${PPIOS_RENAME}" --analyze -x BSClassH "${program}"
toList symbols.map list
verifyFails grep '^BSClassH$' list
verify grep '^methodH$' list

TEST "Excluding a property with -x removes all variants from symbols.map"
run "${PPIOS_RENAME}" --analyze "${program}"
toList symbols.map list
verify grep '^isSquaredA$' list
verify grep '^_squaredA$' list
verify grep '^setIsSquaredA$' list
verify grep '^_isSquaredA$' list
verify grep '^setSquaredA$' list
verify grep '^squaredA$' list
run "${PPIOS_RENAME}" --analyze -x squaredA --emit-excludes excludes "${program}"
toList symbols.map list
verifyFails grep '^isSquaredA$' list
verifyFails grep '^_squaredA$' list
verifyFails grep '^setIsSquaredA$' list
verifyFails grep '^_isSquaredA$' list
verifyFails grep '^setSquaredA$' list
verifyFails grep '^squaredA$' list

report
