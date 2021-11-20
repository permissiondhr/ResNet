`define PARA_WIDTH    'd16           // Width of parameters
`define DATA_WIDTH    'd16           // Width of input data
`define MACRO_O_DW    'd5            // Width of macro output data
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

