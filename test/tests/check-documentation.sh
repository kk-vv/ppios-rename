#!/bin/bash

#Copyright 2016 PreEmptive Solutions, LLC
#See LICENSE.txt for licensing information

targetAppName=BoxSim
thisDirectory="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
testRoot="$(dirname "${thisDirectory}")"
. "${testRoot}/tests/common.sh"

oneTimeSetUp() {
    checkForPPiOSRename
}

oneTimeTearDown() {
    return
}

setUp() {
    return
}

tearDown() {
    return
}

TEST "PPiOS-Rename version referenced in README.md is current"
verify test -f "${README}"
verifyFails test -z "${NUMERIC_VERSION}"

# Find all of the version numbers "x.y.z" in the document, and put them on separate lines.
# The two lines that follow that have trailing backslashes are newlines embedded in the sed
# replacement text, do not indent or otherwise alter.
versionNumbers=$(cat "${README}" | sed -n 's,\([1-9][0-9]*[.][0-9][0-9]*\([.][0-9][0-9]*\)*\),\
\1\
,pg' | grep '[1-9][0-9]*[.][0-9][0-9]*\([.][0-9][0-9]*\)*')

# Remove all of the instances of the expected version number
badVersionNumbers="$(echo "${versionNumbers}" | grep -v "$(echo "^${NUMERIC_VERSION}\$" | sed 's,[.],[.],g')")"

# Verify that nothing is left
verify test -z "${badVersionNumbers}"

report
