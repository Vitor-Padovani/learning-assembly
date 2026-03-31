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
