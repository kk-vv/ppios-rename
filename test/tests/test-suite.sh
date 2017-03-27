#!/bin/bash

#Copyright 2016 PreEmptive Solutions, LLC
#See LICENSE.txt for licensing information

set -e

export PPIOS_RENAME="${PPIOS_RENAME:-ppios-rename}"
echo "Testing:"
type "${PPIOS_RENAME}" | sed 's,.* is ,  ,'

./test-double-obfuscation-protection.sh
./test-filters-and-exclusions.sh
./test-new-options.sh
./test-obfuscate-sources.sh
./test-post-obfuscation-behavior.sh
./check-documentation.sh
