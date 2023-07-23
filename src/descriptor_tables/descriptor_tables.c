#include "descriptor_tables.h"

#include "gdt.h"
#include "idt.h"

#include "string.h"

#include "isr.h"

void init_descriptor_tables()
{
    init_gdt();
    init_idt();

    memset(interrupt_handlers, 0, sizeof(interrupt_handlers));
}