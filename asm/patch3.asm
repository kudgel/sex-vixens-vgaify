BITS 16

cmp al, 1ah
jnz .no
retf
.no:
mov ax, 4c01h
int 21h
