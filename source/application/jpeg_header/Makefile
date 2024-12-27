#
# Authored by: Robert Metchev / Chips & Scripts (rmetchev@ieee.org)
#
# CERN Open Hardware Licence Version 2 - Permissive
#
# Copyright (C) 2024 Robert Metchev
#

HEIGHT ?= 200
WIDTH ?= 200
QF ?= 50

all: header.bin
header.bin: jhdr.exe
	$(<) $(HEIGHT) $(WIDTH) $(QF)
jhdr.exe: jhdr.c main.c
	gcc -o $(@) $(^)

clean:
	rm -f jhdr.exe jhdr.o header.bin
