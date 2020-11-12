#!/usr/bin/env python3
import sys

file = open(sys.argv[1], 'rb')

map = {}
s = []

while True:
	c = file.read(1)
	if not c:
		break
	c = c[0]
	if c == 0x5a:
		c = file.read(1)[0]
		b = file.read(1)[0]
#		print('repeat', c, hex(b))
		s += ([(b>>4) * 16] * 3 + [(b&0xf) * 16] * 3) * c
#	elif c == 0xd:
#		continue
	else:
#		print(hex(c))
		s += [(c>>4) * 16] * 3 + [(c&0xf) * 16] * 3

for x in s:
	map[x] = True

#print(map)
#print(len(s))
sys.stderr.write("bytes: %s colors: %s \n" % (len(s), len(map)))
sys.stdout.buffer.write(b"P6 320 ")
sys.stdout.buffer.write(bytes(str(len(s) // 320 // 3), 'utf8'))
sys.stdout.buffer.write(b" 255 ")
sys.stdout.buffer.write(bytearray(s))
