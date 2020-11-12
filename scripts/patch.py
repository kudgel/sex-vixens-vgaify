#!/usr/bin/env python3
import os

b = bytearray(open('inputs/planlust/PLANETOF.EXE', 'rb').read())

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
    size = os.path.getsize('inputs/planlust/%s.PIQ' % file)
    return '%02x %02x' % (size & 0xff, size >> 8)

def byte_size(file):
    size = os.path.getsize('out/disk/%s.VIQ' % file)
    return '%02x %02x' % (size & 0xff, size >> 8)

b = patch(b, '43 4F 4D 50 41 51', '6b 75 64 67 65 6c')

# Video mode setter

# Original:
# 104d:0048 c6 06 b0        MOV        byte ptr [0x64b0]=>video_mode_2,0xd
#           64 0d
# New:
# mov byte ptr [0x64b0], 0x13

b = patch(b, 'c6 06 b0 64 0d', 
             'c6 06 b0 64 13')

# 104d:0606 80 3e b0        CMP        byte ptr [0x64b0]=>video_mode_2,0xd
#           64 0d
b = patch(b, '8b ec 80 3E B0 64 0D',
             '8b ec 80 3E B0 64 13')

# 104d:12ff 80 3e b0        CMP        byte ptr [0x64b0]=>video_mode_2,0xd
#           64 0d
b = patch(b, '59 80 3E B0 64 0D',
             '59 80 3E B0 64 13')

# Reduce the sleep time by half
# b = patch(b, 'B8 A0 0F 50', 'B8 A0 07 50')

#b = patch(b, '55 8B EC 56 57 8B 46 08 8E C0 8B 7E 06 8B 46 0A 1E 50',
#             'CB 8B EC 56 57 8B 46 08 8E C0 8B 7E 06 8B 46 0A 1E 50')

# draw bitmap
b = patch_variable(b, (0x140 - 0x05), '55 8b ec 56 57 8b 46 08 8e c0 8b 7e 06 8b 46 0a', open('out/asm/patch1.com', 'rb').read())

# Require VGA
# int 10h AH = 1Ah
# http://www.powernet.co.za/info/tables/detect/Vga.Htm
b = patch(b, 'B4 12 B3 10 9A FA 03', 'b8 00 1a 90 9A FA 03')
# AL = 1Ah on success
b = patch_variable(b, 15, '80 fb 10 73 05 b8 01 00 eb 02 33 c0 eb 00 cb', open('out/asm/patch3.com', 'rb').read())

# TitleA
# 0x14bd -> size
b = patch(b, '7c c4 b8 bd 14 50 9a', '7c c4 b8 %s 50 9a' % byte_size('TITLE-A'))
b = patch(b, '83 c4 08 3d bd 14 74 0c 1e', '83 c4 08 3d %s 74 0c 1e' % byte_size('TITLE-A'))

# TitlesS
# 0x1f4b -> size
b = patch(b, '83 c4 08 3d 4b 1f 74 0c', '83 c4 08 3d %s 74 0c' % byte_size('TITLES-5'))

# Add an extra sleep for the first title
# Jump back into the dead space at 104d:022c
# b = patch(b, 'e9 47 01', 'e9 71 ff')
# Call sleep
# b = patch(b, '')
# Jump back to 104d:0402
# ...

# PIQ -> VIQ
b = patch(b, '2E 50 49 51 00', '2E 56 49 51 00')

# Bigger file buffer for later files
b = patch(b, 'b8 ff 7f 50 a0 d9 5f', 'b8 00 a0 50 a0 d9 5f')

# Patch the malloc buffer? (currently 0x6067 = 24679)
# B8 67 60 50 9A 00 00 00 04 59

files = ['BIGT', 'LIMP', 'P1', 'P2', 'P3', 'P4', 'P5', 'P7', 'P7_5',
         '11A', '12A', '13A', '14B', '15E', '16B', '17B', '18B',
         '19B', '20B', '21', '22', '23B', '24A', '25B', '26B', '26C',
         'INTRO_BS', 'INTRO_DD', 'INTRO_PO', 'INTRO_BV']
orig_sizes = ' '.join([orig_byte_size(file) for file in files])
sizes = ' '.join([byte_size(file) for file in files])
b = patch(b, orig_sizes, sizes)

open('out/disk/PLANETOV.EXE', 'wb').write(b)
