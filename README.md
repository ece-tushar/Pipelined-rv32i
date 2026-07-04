# 5-Stage Pipelined RV32I Processor

## Overview

This project implements a 5-stage pipelined RV32I processor in Verilog. It supports the core RV32I instruction subset, data forwarding, hazard detection, and control hazard handling, enabling correct execution of pipelined programs. The design follows a modular datapath and control architecture, with each hardware block developed and verified independently before full processor integration.


## Project Evolution

This processor was developed as an extension of a previously completed single-cycle RV32I processor. The original single-cycle implementation was completed in approximately **17 days**, after which it was upgraded into a fully pipelined design over the course of **5 days**. Rather than redesigning the processor from scratch, the existing datapath components—including the ALU, register file, memories, controller, and immediate generator—were reused and integrated into a 5-stage pipeline with the addition of forwarding logic, hazard detection, pipeline control, and branch/jump support.  

A single monolithic decoder/controller had become very restrictive for a pipelined implementation. So, early in developement, major refactoring work was done to convert it to per-stage decoding. This made implementation and debugging a lot easier, since each decoder is response for its own stage, bugs could be narrowed down very easily. This approach greatly improves modularity for future additions. 

## Features

- Classic 5-stage in-order pipeline (IF, ID, EX, MEM, WB)
- Modular datapath and stage-wise control architecture
- Dedicated pipeline controller for stall and flush management
- Byte-addressable instruction and data memory
- Write-first register file
- Immediate generation for all supported instruction formats
- Load-use hazard detection
- Store data and store address forwarding
- Control hazard handling with pipeline flushing

## Architecture

![Processor Architecture](images/archi_draw.png)

## Supported Instructions

| Category | Instructions                                         |
| -------- | ---------------------------------------------------- |
| R-Type   | ADD, SUB, SLL, SLT, SLTU, XOR, SRL, SRA, OR, AND     |
| I-Type   | ADDI, SLLI, SLTI, SLTIU, XORI, SRLI, SRAI, ORI, ANDI |
| Load     | LB, LH, LW, LBU, LHU                                 |
| Store    | SB, SH, SW                                           |
| Branch   | BEQ, BNE, BLT, BGE, BLTU, BGEU                       |
| Jump     | JAL, JALR                                            |

## Hazard Handling

The processor incorporates dedicated hardware units to resolve both data and control hazards while maintaining pipeline correctness.

### Data Hazard Resolution

* **Forwarding Unit** – Resolves RAW data hazards by forwarding results from the EX/MEM and MEM/WB pipeline stages directly to the ALU operands. This also resolves store address (`rs1`) dependencies during address calculation.
* **Load Hazard Unit** – Detects load-use hazards that cannot be resolved through forwarding and requests a single-cycle pipeline stall.
* **Store Forward Unit** – Implements dedicated forwarding for store data (`rs2`), allowing recently computed values to be written to memory without stalling.

### Control Hazard Resolution

* **Branch Controller** – Evaluates branch conditions, generates branch/jump targets, and issues pipeline redirect requests.
* **Pipeline Controller** – Centralizes pipeline control by coordinating stalls, pipeline flushing, and other control actions required for correct pipeline execution.

