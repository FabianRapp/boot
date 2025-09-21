BITS 16

start:
	cli ;disable interrupts

	; setup segment registers for 16 bit real mode addressing
	mov ax, 0x07c0
	mov ds, ax
	mov es, ax
	;stack from bootloader - 0 growing towowards 0
	xor ax, ax
	mov ss, ax
	mov sp, 0x7C00

	cld ;for forward string indexing

	mov [BOOTDRIVE], dl


	mov di, .BOOTING
	call puts
	jmp .load

.BOOTING db "Booting..", 0
.DRIVE_ERROR db "Drive error", 0
.DRIVE_SUCCESS db "Drive read successfull", 0

.load:
	mov byte [DAP + 0], 16
	mov byte [DAP + 1], 0
	mov word [DAP + 2], 1
	mov word [DAP + 4], loaded_code
	mov word [DAP + 6], ds
	mov si, DAP
	mov dl, [BOOTDRIVE]
	mov ah, 0x42;extended read to read logical disk blocks
	int 0x13 ; bio disk service
	jc .error
	mov di, .DRIVE_SUCCESS
	call puts
	jmp loaded_code

.error:
	mov di, .DRIVE_ERROR
	call puts
	jmp done



puts:
;puts(src)
	push bp ; build stack frame
	mov bp, sp
	push di ; save di since it has to be preserved by called fn
.puts_loop:
	;ax = *di;
	;while (ax) {
	; putc(ax);
	; di++;
	; ax = *di;
	;}
	mov al, [di] ; get the next char
	test al, al ; check null termination
	jz .ret_puts
	mov ax, [di]
	push di
	mov di, ax


	call .putc; puts(current_char)
	pop di
	inc di ; inc ptr

	jmp .puts_loop ; continue

.putc: ;putc(char c)
	push bp
	mov bp, sp
	push bx ; save bx as it has to be preserved by called function

	mov ax, di
	mov ah, 0x0E	   ; BIOS teletype
	mov bh, 0x00	   ; page 0
	mov bl, 0x07	   ; light-grey on black
	int 0x10

	pop bx
	pop bp
	ret


.ret_puts:
	;print collumn return for new line
	mov di, 0x0d
	call .putc
	mov di, 0x0a
	call .putc

	pop di
	pop bp ; pop stack frame
	ret



done:
	mov di, .FINISHED
	call puts
	hlt
	jmp done

.FINISHED db "Bootloader finished", 0


BOOTDRIVE db 0x0, 0

; Disk Address Packet for INT 13h AH=42h
; layout:
; 0 size (byte)
; 1 reserved (byte)
; 2-3 sectors to transfer (word)
; 4-5 buffer offset (word)
; 6-7 buffer segment (word)
; 8-15 starting LBA (qword)
DAP:
    db 2 ; size
    db 0 ; reserved
    dw 1 ; sectors
    dw 0x0 ; offset
    dw 0x0000 ; segment
    dq 1 ; LBA start = 1  (i.e., the second 512B sector)

times 510-($-$$) db 0

.magic:
; boot signature 0xAA55 in little endian
db 0x55
db 0xAA

loaded_code:
	mov di, LOADED_CODE
	call puts
	jmp done

LOADED_CODE db "Code from loaded_code", 0

times 1024-($-$$) db 0

;.enter_long_mode:
	;enter protected mode
	;load page table 
	;set efer.lme in msr
	; jmp 64 bit mode
	; load kernel from disk


