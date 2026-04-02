# learning-assembly

```
gcc hello_printf.s -o a && ./a
```

## GDB

```
gcc -g a.s -o a
gdb a
b main
r
layout regs / linfo registers
n
...
q
```

Ou

```
make debug FILE=a
```

## Instructions:

- movb (Byte): Move 8 bits (1 byte).
- movw (Word): Move 16 bits (2 bytes).
- movl (Long): Move 32 bits (4 bytes).
- movq (Quad): Move 64 bits (8 bytes)
