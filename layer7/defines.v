`define PARA_WIDTH    'd16           // Width of parameters
`define DATA_WIDTH    'd16           // Width of input data
`define MACRO_O_DW    'd4            // Width of macro output data
`define DECODER_O_DW  'd4            // Width of decoder output data
`define RSTVALID     1'b0            // Reset Validation, Active LOW
`define RSTINVALID   1'b1            // Reset Invalidation

// Mode Switch
`define LOAD_PARA    1'b0            //
`define CALCULATE    1'b1
// DATA Enalbe 
`define DATAVALID    1'b1
`define DATAINVALID  1'b0
// VSync
`define VSVALID      1'b1
`define VSINVALID    1'b0

// Debug mode
`define DB_DISABLE   3'b000          // Debug mode disable, execute          Normal Calculation.
`define DB_WR_CAL    3'b001          // Normal Calculation, and write Result to SRAM simultaneously.          
`define DB_WR_OFF    3'b001          // Write SRAM from off-chip input.                                              
`define DB_BYPASS    3'b011          // Bypassing the result of current layer, and read data direct from SRAM.
`define DB_RE_OFF    3'b100          // Send data to Outside, every four clock cycle.

