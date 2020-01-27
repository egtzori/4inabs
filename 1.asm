[bits 16]           ; tell assembler that working in real mode(16 bit mode)  
[org 0x7c00]        ; organize from 0x7C00 memory location where BIOS will load us  

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
start:
  ; cls
  mov ax, 0xb800
  mov es, ax
  xor di, di
  mov cx, 0x07d0
  mov ax, 0x0000
  rep stosw

;;;;; print bottomrow - 1 to 7
  mov ax, rowstart+90
  mov es, ax
  xor di, di
  mov ax,0x0231
.loop_printbr:
  mov word [es:di], ax
  inc di
  inc di
  inc ax
  cmp al, 0x38
  jne .loop_printbr
.done:

;;;;

mov ax, rowstart+162
mov es, ax

mov si, msg_playerturn ; 'go' or 'Player' text
mov bh, 12 ; color
call message

.loop1:
  call showmsg_playerturn
  mov ah, 0               ; wait for key
  int 016h

; action: ; key in al
  ; cmp al, 0x72 ; 'r'
  ; jne .next
  ; call reboot
  cmp al, 0x30
  jbe .loop1
  sub al, 0x30
  cmp al, 7
  jg .loop1
  call play

  jmp .loop1

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

rowstart equ 0xb800
browlen equ 80*2
playerturn db 0 ; 0 = player1, 1 = player2
syms db 'XO' ; to draw
; symplayer db '12' ; to draw
symcolors db 0x40,0x12 ; to draw
; turns db 0 ;turns counter - removed cuse no memory
; barrier db 1 ; FIXME - this gets overwritten

msg_playerturn db 'Go',0
; msg_gameend_draw db 'Game ended draw',0
msg_gameend_winner db 'Win ',0

message:                        ; Dump si to screen.
  xor di, di
.loop:
  mov cl, [si]
  test cl, cl
  jz .done
  mov ch, bh
  mov word [es:di], cx
  inc di
  inc di
  inc si
  jmp .loop
.done:
  ret

showmsg_playerturn:
  mov ax, rowstart+162
  mov es, ax

  mov al, [playerturn]
  add al, 0x31
  mov ah, 12 ; color

  mov word [es:16], ax
  ret

showmsg_playerwin:
  mov ax, rowstart+200
  mov es, ax

  mov si, msg_gameend_winner
  mov bh, 13 ; color
  call message

  mov al, [playerturn]
  add al, 0x31
  mov ah, ch ; color
  mov word [es:di], ax

  mov ah, 0               ; wait for key
  int 0x16
  call reboot
  ret;

play: ; key in al
  ; double al and store key offset in bx
  dec ax ;; key 1 = row 0
  shl ax, 1
  xor ah, ah; and ax, 0xff
  mov bx, ax

  mov ax, 160
  mov cx, 7 ; ROWLEN
  imul cx

  add ax, bx
  mov si, ax

  push rowstart
  pop es

.nextrow:  ;; look for empty
  cmp word [es:si], 0
  jz .found
  sub si, 160
  inc cx
  jmp .nextrow
  ;; ERR cant play
  ret
.found:
  ; mov di, playerturn
  mov al, byte [playerturn]
  mov bx, symcolors
  xlat ; tr colors
  mov ah, al
  mov al, byte [playerturn]
  mov bx, syms
  xlat
  mov word [es:si], ax

  call check_win ;; check before ending turn

  mov al, byte[playerturn] ;; next player
  xor al, 1
  mov byte [playerturn], al

  ; mov si, turns
  ; inc si
  ; mov byte [si], turns

  ret

check_win: ; my symbol in ax
  ;; start line ...X
  ; mov ax, [es:si-6]
  ; add ax, [es:si-4]
  ; add ax, [es:si-2]
  ; add ax, [es:si]
  ; cmp ax, 0x0160
  ; je .win
  ; cmp ax, 0x493c
  ; je .win


  ; start line ...X
  mov al, byte [es:si]  ; last played pos
  add al, byte [es:si-6]
  add al, byte [es:si-4]
  add al, byte [es:si-2]
  cmp al, 0x3c
  je .win
  cmp al, 0x60
  je .win

  ; ..X.
  sub al, [es:si-6]
  add al, [es:si+2]
  cmp al, 0x3c
  je .win
  cmp al, 0x60
  je .win

  ; .X..
  sub al, [es:si-4]
  add al, [es:si+4]
  cmp al, 0x3c
  je .win
  cmp al, 0x60
  je .win

  ; X...
  sub al, [es:si-2]
  add al, [es:si+6]
  cmp al, 0x3c
  je .win
  cmp al, 0x60
  je .win
  ;;;;;;;; end horizontal
  
  ;; do vertical
  mov al, byte [es:si]  ; last played pos
  add al, [es:si+160*1]
  add al, [es:si+160*2]
  add al, [es:si+160*3]
  cmp al, 0x3c
  je .win
  cmp al, 0x60
  je .win
  ;;;;;;;;; end vertical

  ;; do diagonals
  ; top left to bottom right
  mov al, byte [es:si]  ; last played pos
  add al, [es:si-160*3-6]
  add al, [es:si-160*2-4]
  add al, [es:si-160*1-2]
  ;; call testwin
  cmp al, 0x3c
  je .win
  cmp al, 0x60
  je .win

  sub al, [es:si-160*3-6]
  add al, [es:si+160*1+2]
  cmp al, 0x3c
  je .win
  cmp al, 0x60
  je .win

  sub al, [es:si-160*2-4]
  add al, [es:si+160*2+4]
  cmp al, 0x3c
  je .win
  cmp al, 0x60
  je .win

  sub al, [es:si-160*1-2]
  add al, [es:si+160*3+6]
  cmp al, 0x3c
  je .win
  cmp al, 0x60
  je .win

  ; top right to bottom left
  mov al, byte [es:si]  ; last played pos
  add al, [es:si-160*3+6]
  add al, [es:si-160*2+4]
  add al, [es:si-160*1+2]
  cmp al, 0x3c
  je .win
  cmp al, 0x60
  je .win

  sub al, [es:si-160*3+6]
  add al, [es:si+160*1-2]
  cmp al, 0x3c
  je .win
  cmp al, 0x60
  je .win

  sub al, [es:si-160*2+4]
  add al, [es:si+160*2-4]
  cmp al, 0x3c
  je .win
  cmp al, 0x60
  je .win

  sub al, [es:si-160*1+2]
  add al, [es:si+160*3-6]
  cmp al, 0x3c
  je .win
  cmp al, 0x60
  je .win
  ;;;;;;;;; end diagonals


  ; mov bx, 68
  ; call _printal

  ret

.win:
  call showmsg_playerwin
  ret;

reboot:
  db 0EAh                 ; machine language to jump to FFFF:0000 (reboot)
  dw 0000h
  dw 0FFFFh

times (510 - ($ - $$)) db 0x00     ;set 512 BS
dw 0xAA55
