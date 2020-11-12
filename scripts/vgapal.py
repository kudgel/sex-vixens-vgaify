#!/usr/bin/env python3
import sys
pal = sys.stdin.buffer.read()[13:]
sys.stdout.buffer.write(bytes([x>>2 for x in pal]))
