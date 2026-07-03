# Upgrading a single cycle processor to a 5 stage pipelined processor

Under development. 
- Added IF_ID pipeline registers
- Adder ID_EX pipeline registers
- Dropped support for LUI/AUIPC for now.
- branches/jumps will be impplemented after complete pipeline implementation. 
- Basic pipeline implementation complete.
- Hazards handling / branch control under implementation.
- Moved from ID stage decoding to per stage decoding, simplifes later upgradations. 
- Added R/R-I type Forwarding unit
- Added load-use hazard detection unit.
- Implemented one-cycle pipeline stall with bubble insertion.
- Introduced centralized pipeline control for future hazard/branch handling.
- Added PC and IF/ID write enable support for controlled pipeline stalling.
- Bug discovered on sourcing a register being WB on the same cycle.
- solved by make regbank explicitly write first. 

---

Pipeline data hazards complete

- Implement write-first register file
- Add EX/MEM and MEM/WB operand forwarding
- Add load-use hazard detection and pipeline stall
- Add store forwarding
- Verify loads and stores
- Pass comprehensive pipeline regression

---

Implement branch support in 5-stage RV32I pipeline

- Added branch forwarding support
- Added load-to-branch hazard detection
- Implemented BranchController
- Added pipeline flush on taken branches
- Added PC pipelining and branch target feedback
- Verified branch execution, forwarding, and load hazards through regression tests

---

- Added branch handling, JAL/JALR and control hazard support
