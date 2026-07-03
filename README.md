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
