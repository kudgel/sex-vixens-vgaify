BITS 16
ORG 100h

mov ax, 0x1a00
int 10h
cmp al, 1ah
je .yes
mov ax, 0x4c00
int 21h
.yes:
mov ax, 0x4c01
int 21h
