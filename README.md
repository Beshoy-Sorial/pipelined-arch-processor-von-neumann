# pipelined-arch5

A 5-stage pipelined CPU implemented in VHDL with hazard handling, a compact custom 32-bit ISA, and a Python assembler that converts assembly into machine code for simulation and synthesis. The processor follows a Von Neumann architecture with unified instruction/data memory and includes proper structural hazard handling.

---

## Project goals
- Design and implement a 5-stage pipelined processor (IF, ID, EX, MEM, WB) in VHDL.
- Define a simple, well-documented 32-bit ISA and instruction word formats.
- Implement hazard control: data hazards, control hazards, and structural hazards due to a single unified memory.
- Provide a Python assembler to translate assembly to machine code (.mem/.hex) for simulation.
- Modular VHDL design so every stage/unit can be tested independently.

---

## Features
- 5-stage pipeline: Instruction Fetch (IF), Instruction Decode/Register Fetch (ID), Execute (EX), Memory Access (MEM), Write Back (WB).
- Hazard unit implementing:
  - **Data hazards:** forwarding (EX→EX, MEM→EX) and load-use stalls.
  - **Control hazards:** static not-taken scheme with flushing on taken branches; optional 2-bit predictor stub.
  - **Structural hazards:** because the design uses a **Von Neumann architecture**, both instructions and data share one memory. IF–MEM contention is handled by memory arbitration + pipeline stalls.
- Custom 32-bit instruction set with R-type, I-type, and J-type formats.
- Register file with 32 registers (R0..R31), with R0 hardwired to zero.
- ALU supporting add, sub, and/or/xor, shifts, compare.
- Load/store support with byte/word access.
- Python assembler that emits memory initialization files for simulation (`.mem` / hex).

---

## ISA summary & instruction word formats

All instructions are 32 bits. Formats:

### R-type (register)
### I-type (immediate / loads / branches)
### J-type (jump)

---

## Pipeline & hazard handling

### Data hazards
- Forwarding paths:
  - EX/MEM → EX  
  - MEM/WB → EX  
- Load-use hazard:
  - If EX stage contains `LW` and next instruction uses its destination register, stall 1 cycle and insert bubble.

### Control hazards
- Static **not-taken** prediction.
- If branch is taken in EX:
  - Flush IF/ID.
  - Update PC to branch target.
- module for 2-bit branch predictor.

### **Structural hazards (Von Neumann)**
Because instruction and data use **one unified memory**, IF and MEM may conflict.

Handled using one of the following:

#### 1) Simple stall 
- When MEM stage performs read/write, memory is “busy”.
- IF stage must stall until memory becomes free.
- Hazard unit asserts:
  - `stall_if`
  - `stall_id`
- PC and IF/ID register freeze when stalling.

#### 2) Arbiter 
- Memory arbiter gives priority to MEM over IF.
- IF stalls only when MEM needs memory.

---

## Python assembler
- `assembler/assemble.py`
- Converts `.s` assembly → `.mem` or `.hex`
- Supports:
  - labels
  - `.org`, `.word` , '.txt'
