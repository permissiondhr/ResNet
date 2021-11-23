`include "defines.v"
module macro 
(
    input  wire                              adc                      ,
    input  wire                              enable                   ,
    input  wire        [1 : 0]               chs_ps                   ,
    input  wire signed [0 : 0]               data_in [31  : 0][8 : 0],
    output reg  signed [`MACRO_O_DW - 1 : 0] data_out[63  :  0] 
);
    
endmodule
