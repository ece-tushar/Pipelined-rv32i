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

## Key Design Decisions

Throughout development, several architectural refactoring decisions were made to improve the scalability and maintainability of the processor:

* **Modular Pipeline Control** – The original monolithic controller was decomposed into dedicated hardware modules, including the Forwarding Unit, Load Hazard Unit, Store Forward Unit, Branch Controller, and Pipeline Controller. This separation of responsibilities simplified debugging and enabled independent feature development.

* **Stage-wise Instruction Decoding** – Centralized instruction decoding was replaced with per-stage decoding, allowing each pipeline stage to decode only the information it required. This significantly improved modularity and eased the addition of new instructions.

* **Write-First Register File** – The register file was redesigned to support write-first behavior, eliminating WB→ID read-after-write hazards without introducing additional forwarding paths.

* **Operand-Oriented Forwarding Architecture** – Rather than forwarding based solely on instruction type, the forwarding logic was reorganized around ALU operand usage. This naturally accommodated stores, branches, and jump instructions while reducing duplicated logic.

* **Incremental Feature Verification** – New pipeline features were introduced and verified one at a time using dedicated regression programs and version-controlled checkpoints. This approach greatly simplified debugging and prevented architectural regressions during development.

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

