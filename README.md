# sm

A Simple Virtual Machine.

## Example Programs

You can see more example programs [here](https://github.com/DirectMyFile/sm/tree/master/example).

```
# Countdown from 5 to 1
PSH 5 # Starting Point
DUP # Duplicate
PRNT # Print Value
PSH 1 # Push 1
SUB # Subtract 1 from the Value
DUP # Duplicate
PSH 0 # Push 0
PSH 11 # Push 11
JIE # Jump to End
PSH 1 # Instruction 1
JMP # Jump to Instruction 1
HLT # Halt
```

## Instructions

```
HLT (1): Halt Program
PSH (2): Push Value to Stack
POP (3): Pop Value from Stack
ADD (4): Add last 2 values on the stack and push the value to the stack
JMP (5): Jump Instructions
DUP (6): Duplicate Last Stack Value
JIE (7): Jump if Equal
JINE (8): Jump if Not Equal
PRNT (9): Print Last Stack Value
FLP (10): Flip
ROT (11): Rotate
OIEE (12): One if Either Equal
SUB (13): Subtract
SIZ (14): Size of Stack
PSTK (15): Print Stack
SRV (16): Set Register Value
CRS (17): Copy Register Value to Stack
ENTR (18): Create and Enter New Stack
SHFT (19): Shift Stack
RSET (20): Reset Program
LEAV (21): Leave the Current Stack
MULT (22): Multiply
NOP (23): Do Nothing
EVAL (24): Evaluate the Current Stack as a Program
CLR (25): Clear the Stack
SYSC (26): Make a System Call
CPC (27): Copy Program Code to Stack
SDUP (28): Duplicate Entire Stack
EFLP (29): Flip Every Pair of Stack Values
FRK (30): Fork a Virtual Thread
SPI (31): Set Program Instruction
CENTR (32): Copy Current Stack to a New Stack and Enter It
```

## Serving the web interface

The interface will be available [here](http://localhost:8080/try.html) after you run the following.

```
pub get
pub serve
```
