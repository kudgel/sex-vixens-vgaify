#!/usr/bin/env python3
import sys

all = sys.stdin.buffer.read()

# Pre-shift the palette
all[:-768] = [x>>2 for x in all[:-768]]

# Trim PCX header only (leave palette)
sys.stdout.buffer.write(all[128:])
