#!/usr/bin/env python3
import sys

all = bytearray(sys.stdin.buffer.read())
len1 = len(all)

# Pre-shift the palette
all[-768:] = [x>>2 for x in all[-768:]]

# Just to be sure
assert(len1 == len(all))

# Trim PCX header only (leave palette)
sys.stdout.buffer.write(all[128:])
