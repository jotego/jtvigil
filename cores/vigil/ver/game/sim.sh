#!/bin/bash

eval `jtcfgstr -core vigil -output bash`

if [ ! -e rom.bin ]; then
    ln -s $ROM/vigilant.rom rom.bin || exit $?
fi

rm -rf obj_dir
jtsim -mist -sysname vigil -verilator $*