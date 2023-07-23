#ifndef IDT_H
#define IDT_H


#include "types.h"


#define     PIC1_COMMAND_PORT               0x20
#define     PIC1_DATA_PORT                  0x21
#define     PIC2_COMMAND_PORT               0xA0
#define     PIC2_DATA_PORT                  0xA1


#define STRINGIFY(x) #x
#define INTERRUPT(num) asm volatile("int $" STRINGIFY(num))


// A struct describing an interrupt gate.
struct idt_entry_struct
{
   u16 base_lo;             // The lower 16 bits of the address to jump to when this interrupt fires.
   u16 sel;                 // Kernel segment selector.
   u8  always0;             // This must always be zero.
   u8  flags;               // More flags. See documentation.
   u16 base_hi;             // The upper 16 bits of the address to jump to.
} __attribute__((packed));
typedef struct idt_entry_struct idt_entry_t;

// A struct describing a pointer to an array of interrupt handlers.
// This is in a format suitable for giving to 'lidt'.
struct idt_ptr_struct
{
   u16 limit;
   u32 base;                // The address of the first element in our idt_entry_t array.
} __attribute__((packed));
typedef struct idt_ptr_struct idt_ptr_t;


void init_idt();
void enable_interrupts();


#endif //IDT_H