#!/bin/bash

eval `jtcfgstr -core vigil -output bash`

if [ ! -e rom.bin ]; then
    ln -s $ROM/vigilant.rom rom.bin || exit $?
fi

jtsim -mist -sysname vigil $*