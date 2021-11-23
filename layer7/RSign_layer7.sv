`include "defines.v"
module RSign_layer7
#(
    parameter FM_DEPTH     = 256           // Depth of the Feature Map
)
(
    input  wire                              clk                              , // System Clock
                                             rst_n                            , // System Reset, Active LOW
                                             data_e                           , // DATA Enable signal, Active HIGH
                                             // Mode Switch, LOW -> Reload parameter; HIGH -> Calculate
                                             mode                             ,  
    input  wire signed [`PARA_WIDTH - 1 : 0] para    [FM_DEPTH - 1 : 0]       , // RSign Parameter input
    input  wire signed [`DATA_WIDTH - 1 : 0] data_in [FM_DEPTH - 1 : 0][8 : 0], // Input Data
    input  wire        [1               : 0] chs_macro_in                     , // counter == 1 indicate that the data is after down simpling.
    output reg         [1               : 0] chs_macro_out                    ,
    output reg  signed [0               : 0] data_out[FM_DEPTH - 1 : 0][8 : 0]  // Output Data after RSign                 
);

    genvar  i, j;
    generate 
        for(i = 0; i < FM_DEPTH; i = i + 1) begin: data_out_loop
            for(j = 0; j< 9; j = j + 1) begin
                always @(posedge clk or negedge rst_n) begin
                    if(rst_n == `RSTVALID) begin    // When RESET is valid, reset data_out, data_e_out
                        data_out[i][j] <= 1'b0;
                        //data_e_out_tmp     <= `DATAINVALID;
                    end else if(mode == `CALCULATE && data_e == `DATAVALID) begin
                        data_out[i][j] <= data_in[i][j] > para[i] ? 1'b1 : 1'b0;
                        //data_e_out_tmp     <= `DATAVALID;
                    end else begin
                        data_out[i][j] <= data_out[i][j];
                        //data_e_out_tmp     <= `DATAINVALID;
                    end//if
                end //always
            end // for j
        end // for i
    endgenerate // generate

    always @(posedge clk) begin
        chs_macro_out <= chs_macro_in;
    end //always

endmodule // RSign_layer5