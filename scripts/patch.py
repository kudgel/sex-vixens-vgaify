#!/usr/bin/env python3
import os

b = bytearray(open('sexvixen/SEXVIXEN.EXE', 'rb').read())

def patch(b, in_bytes, out_bytes):
    in_bytes = bytes([int('0x%s' % x, 16) for x in in_bytes.split(' ')])
    out_bytes = bytes([int('0x%s' % x, 16) for x in out_bytes.split(' ')])
    if len(in_bytes) != len(out_bytes):
        raise("Size mismatch: in != out")
    b2 = b.replace(in_bytes, out_bytes)
    if b2 == b:
        raise("Didn't find a replacement")
    return b2

def patch_variable(b, max_len, in_bytes, out_bytes):
    if len(out_bytes) > max_len:
            raise("Too many bytes")
    in_bytes = bytes([int('0x%s' % x, 16) for x in in_bytes.split(' ')])
    idx = b.find(in_bytes)
    if idx == -1:
        raise("Didn't find the source")
    b[idx:idx+len(out_bytes)] = out_bytes
    return b

def orig_byte_size(file):
    size = os.path.getsize('inputs/sexvixen/%s.PIQ' % file)
    return '%02x %02x' % (size & 0xff, size >> 8)

def byte_size(file):
    size = os.path.getsize('out/disk/%s.VIQ' % file)
    return '%02x %02x' % (size & 0xff, size >> 8)

b = patch(b, '43 4F 4D 50 41 51', '6b 75 64 67 65 6c')

# Video mode setter

# 0x935e
# mov
b = patch(b, 'c6 06 5e 93 0d', 
             'c6 06 5e 93 13')
# cmp1
b = patch(b, '8b ec 80 3E 5e 93 0D',
             '8b ec 80 3E 5e 93 13')
# cmp2
b = patch(b, '59 80 3E 5e 93 0D',
             '59 80 3E 5e 93 13')

# Reduce the sleep time by half
# b = patch(b, 'B8 A0 0F 50', 'B8 A0 07 50')

#b = patch(b, '55 8B EC 56 57 8B 46 08 8E C0 8B 7E 06 8B 46 0A 1E 50',
#             'CB 8B EC 56 57 8B 46 08 8E C0 8B 7E 06 8B 46 0A 1E 50')

# draw bitmap
b = patch_variable(b, (0x140 - 0x05), '55 8b ec 56 57 8b 46 08 8e c0 8b 7e 06 8b 46 0a', open('patches/patch1.com', 'rb').read())

# Require VGA
# int 10h AH = 1Ah
# http://www.powernet.co.za/info/tables/detect/Vga.Htm
b = patch(b, 'B4 12 B3 10 9A FA 03', 'b8 00 1a 90 9A FA 03')
# AL = 1Ah on success
b = patch_variable(b, 15, '80 fb 10 73 05 b8 01 00 eb 02 33 c0 eb 00 cb', open('patches/patch3.com', 'rb').read())

# TITLE
# 0x2176 -> size
b = patch(b, '7c c4 b8 76 21 50 9a', '7c c4 b8 %s 50 9a' % byte_size('TITLE'))
b = patch(b, '83 c4 08 3d 76 21 74 0c 1e', '83 c4 08 3d %s 74 0c 1e' % byte_size('TITLE'))

# TITLE2
# 0x4814 -> size
b = patch(b, '1e b8 44 8d 50', '1e b8 ce 7c 50')
b = patch(b, '83 c4 08 3d 14 48 74 0c', '83 c4 08 3d %s 74 0c' % byte_size('TITLE2'))

# Add an extra sleep for the first title
# Jump back into the dead space at 104d:022c
# b = patch(b, 'e9 47 01', 'e9 71 ff')
# Call sleep
# b = patch(b, '')
# Jump back to 104d:0402
# ...

# PIQ -> VIQ
b = patch(b, '2E 50 49 51 00', '2E 56 49 51 00')

# Bigger malloc buffer (5665->a000)
# This needs to be bigger than the largest possible file we might load
b = patch(b, 'c7 06 bb 90 d4 1b b8 65 56 50', 'c7 06 bb 90 d4 1b b8 00 b0 50')
# Bigger file buffer for TITLE2
b = patch(b, 'B8 FF 7F 50 FF 36 6D 93', 'B8 00 b0 50 FF 36 6D 93')
# Bigger file buffer for earlier files
b = patch(b, 'b8 ff 7f 50 a0 42 8d', 'b8 00 b0 50 a0 42 8d')
# Bigger file buffer for later files
b = patch(b, 'b8 ff 7f 50 a0 43 8d', 'b8 00 b0 50 a0 43 8d')

files = ['GPANEL', 'LOBBY', 'HOTEL', 'BIGT', 'LIMP', 'END', 'P1', 'P2', 'P3', 'P4',
    'P5', 'P7', 'P7_5', 'P8', 'P9', 'P10', 'P11', 'P12', 'P13_5', 'P14', 'P15',
    'P16', 'P17', 'P18', 'P19', 'P1_5', 'P20', 'P21', 'P23', 'P24', 'P25', 'P26',
    'P27', 'P28', 'P29', 'P30', 'P31', 'P32', 'P33']
orig_sizes = ' '.join([orig_byte_size(file) for file in files])
sizes = ' '.join([byte_size(file) for file in files])
b = patch(b, orig_sizes, sizes)

open('out/disk/SEXVIXEV.EXE', 'wb').write(b)
