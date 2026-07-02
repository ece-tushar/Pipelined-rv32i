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
