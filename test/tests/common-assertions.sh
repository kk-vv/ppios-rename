#!/usr/bin/env false
# this script is intended to be sourced by other scripts, not run directly

#Copyright 2017 PreEmptive Solutions, LLC
#See LICENSE.txt for licensing information

assertDeobfuscatedCrashdump() {
    verify grep -- '-\[BSClassP doSomethingP:]' "$1"
    verify grep -- '-\[BSClassO doSomethingO:]' "$1"
    verify grep -- '+\[BSClassN doSomethingInClassN:]' "$1"
    verify grep -- '-\[BSClassM doSomethingM:]' "$1"
    verify grep -- '-\[ViewController justGoAction:]' "$1"
}
