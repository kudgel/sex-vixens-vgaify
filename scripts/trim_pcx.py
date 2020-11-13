#!/usr/bin/env python3
import sys

bits = open(sys.argv[1], 'rb').read().replace(b"\n", b' ').split(b' ')
pal_count = int(bits[1]) * int(bits[2])
pal_count = pal_count + 10

all = bytearray(sys.stdin.buffer.read())
len1 = len(all)

# Pre-shift the palette
pal = [x>>2 for x in all[-768:]]

# # Trim the palette and add zeros
# pal = pal[:pal_count*3]
# pal.extend([0] * 768)
# # Back to 768
# pal = pal[:768]

all[-768:] = pal

# Just to be sure
assert(len1 == len(all))

# Trim PCX header only (leave palette)
sys.stdout.buffer.write(all[128:])
