#!/usr/bin/env python3
import sys

all = sys.stdin.buffer.read()

# Trim PCX header and palette
sys.stdout.buffer.write(all[128:-769])
