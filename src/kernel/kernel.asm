[BITS 32]


global _mb_boot


extern code
extern bss
extern end


_mb_ALIGN               equ  1 << 0                        ; align loaded modules on page boundaries
_mb_MEMINFO             equ  1 << 1                        ; provide memory map
_mb_FLAGS               equ  _mb_ALIGN | _mb_MEMINFO       ; this is the Multiboot 'flag' field
_mb_MAGIC               equ  0x1BADB002                    ; 'magic number' lets bootloader find the header
_mb_CHECKSUM            equ -(_mb_MAGIC + _mb_FLAGS)       ; checksum of above, to prove we are multiboot


section .note.GNU-stack noalloc noexec nowrite progbits


section .multiboot
_mb_boot:
align 4
    dd _mb_MAGIC
    dd _mb_FLAGS
    dd _mb_CHECKSUM

    dd _mb_boot
    dd code
    dd bss
    dd end
    dd _mb_start


section .bss
__bss_start:
align 16
	_mb_stack_bottom
	resb 8192			; 8KB for stack
	_mb_stack_top
__bss_end:


section .text
	global _mb_start:function (_mb_start.mb_end - _mb_start)
	; Include the GDT from previous tutorials
	; Set this as our GDT with LGDT
	; insetad of relying on what the bootloader sets up for us
	%include "src/kernel/gdt.asm"

	; Make global anything that is used in C files
	global start
	global load_gdt
	global load_idt
	global keyboard_handler
	global ioport_in
	global ioport_out
	global inl
	global outl
	global enable_interrupts

	extern main			; Defined in kernel.c
	extern handle_keyboard_interrupt

	load_gdt:
		lgdt [gdt_descriptor] ; from gdt.asm
		ret

	load_idt:
		mov edx, [esp + 4]
		lidt [edx]
		ret

	enable_interrupts:
		sti
		ret

	keyboard_handler:
		pushad
		cld
		call handle_keyboard_interrupt
		popad
		iretd

	ioport_in:
		mov edx, [esp + 4] ; PORT_TO_READ, 16 bits
		; dx is lower 16 bits of edx. al is lower 8 bits of eax
		; Format: in <DESTINATION_REGISTER>, <PORT_TO_READ>
		in al, dx					 ; Read from port DX. Store value in AL
		; Return will send back the value in eax
		; (al in this case since return type is char, 8 bits)
		ret

	ioport_out:
		mov edx, [esp + 4]	; port to write; DST_IO_PORT. 16 bits
		mov eax, [esp + 8] 	; value to write. 8 bits
		; Format: out <DST_IO_PORT>, <VALUE_TO_WRITE>
		out dx, al
		ret

	inl:
		mov edx, [esp + 4]
		in eax, dx
		ret

	outl:
		mov edx, [esp + 4]
		mov eax, [esp + 8]
		out dx, eax
		ret

	start:

		push ebx				   ; load multiboot header location; store for access in main()

		; now we load C GDT
		; THANK YOU MICHAEL PETCH
		; https://stackoverflow.com/questions/62885174/multiboot-keyboard-driver-triple-faults-with-grub-works-with-qemu-why
		;lgdt [gdt_descriptor]
		;jmp CODE_SEG:.setcs       ; Set CS to our 32-bit flat code selector
		;.setcs:
		;mov ax, DATA_SEG          ; Setup the segment registers with our flat data selector
		;mov ds, ax
		;mov es, ax
		;mov fs, ax
		;mov gs, ax
		;mov ss, ax
		;mov esp, stack_space        ; set stack pointer

		cli				; Disable interrupts

		mov edi, __bss_start
		mov ecx, __bss_end - __bss_start
		xor eax, eax
		rep stosb
		call main

		.mb_hang:
			hlt
			jmp .mb_hang
		.mb_end: