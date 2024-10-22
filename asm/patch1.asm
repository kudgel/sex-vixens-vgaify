BITS 16

; param1 = bitmap
; param2 = new ES
; param3 = length of bytes we're drawing

; lodsb: ds:si -> al
; stosb: al -> es:di
; movsb: ds:si -> es:di

push bp
mov bp, sp
pusha
push es
push ds
pushf
cld

; zero palette
mov dx, 3c6h
mov al, 0xff
out dx, al
inc dx
inc dx
mov al, 16 ; start after EGA
out dx, al
inc dx
mov al, 0fh
mov cx, ((256 - 16) * 3)
.loop_pal:
out dx, al
loop .loop_pal


; ds:si = param
mov ax, word [ss:bp + 8] ; param2
mov ds, ax
mov si, word [ss:bp + 6] ; param1
; cx = blit size
mov cx, word [ss:bp + 10] ; param3
shl cx, 1

; es:di = a000:0000
mov ax, 0xa000
mov es, ax 
mov di, 0
xor ax, ax

.loop:

lodsb
cmp al, 0xc0
ja .repeat
stosb
loop .loop
jmp .done

.repeat:
sub al, 0xc0 ; len
sub cx, ax
inc cx
push cx ; stash
movzx cx, al
lodsb ; byte -> al
rep stosb
pop cx ; unstash cx
loop .loop

.done:

; 0c
lodsb

; splat real palette
mov dx, 3c6h
mov al, 0xff
out dx, al
inc dx
inc dx
xor al, al
out dx, al
inc dx
mov cx, (256 * 3)
rep outsb


call near .getip
.getip: 
pop si
add si, (.flag - $ + 1)

cmp byte [cs:si], 0x99
je .skipsleep
mov byte [cs:si], 0x99

; Sleep
mov ax, 8600h
mov cx, 30
mov dx, 2
int 15h
jc .error

jmp .skipsleep

.error:
mov ax, 0003h
int 10h
mov ax, 4c10h
int 21h

.skipsleep:
popf
pop ds
pop es
popa
pop bp
retf

.flag:
db 4
