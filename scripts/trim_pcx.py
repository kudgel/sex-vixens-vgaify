#!/usr/bin/env python3
import sys
import re

ega = b'\x00\x00\x00\x00\x00\xaa\x00\xaa\x00\x00\xaa\xaa\xaa\x00\x00\xaa\x00\xaa\xaaU\x00\xaa\xaa\xaaUUUUU\xffU\xffUU\xff\xff\xffUU\xf6n\xc3\xff\xffD\xff\xff\xff'
pal = re.findall(b'...', ega)
pal_index = {}
for p, i in enumerate(pal):
    pal_index[i] = p

all = bytearray(sys.stdin.buffer.read())
all = all.split(b'255', 2)[1][1:]

pixels = re.findall(b'...', all)

out = bytearray()

last = ''
count = 1

def write_pixel(last, count):
    if last == '':
        return
    while count >= 63:
        out.append(0xff)
        out.append(pal_index[last])
        count -= 63
    if count == 0:
        pass
    elif count == 1:
        out.append(pal_index[last])
    else:
        out.append(0xc0 + count)
        out.append(pal_index[last])

for pixel in pixels:
    if pal_index.get(pixel) == None:
        pal_index[pixel] = len(pal)
        pal.append(pixel)
    if last == pixel:
        count = count + 1
    else:
        write_pixel(last, count)
        last = pixel
        count = 1

write_pixel(last, count)

sys.stdout.buffer.write(out)
sys.stdout.buffer.write(b'\x0c')
for p in pal:
    sys.stdout.buffer.write(bytearray([b>>2 for b in p]))
