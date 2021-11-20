`include "defines.v"
module macro_layer7 
#(
    parameter FM_DEPTH     = 'd256,         // Depth of the Feature Map
    parameter CHANNEL_NUM  = 'd512,         // Channel number of Macro
    parameter MACRO_NUM    = 'd32            // There are 64 Macro in Layer 7, but split to 2*32 macro
)
(
    input wire                               clk                                             ,
                                             rst_n                                           ,
                                             latch                                           ,
                                             adc                                             ,
                                             macro_e                                         ,
                                             data_e                                          ,
    input  wire signed [0 : 0]               data_in [FM_DEPTH/2 - 1  : 0][8             : 0],
    output reg  signed [`MACRO_O_DW - 1 : 0] data_out[CHANNEL_NUM - 1 : 0][MACRO_NUM - 1 : 0]      
);
    reg [3 : 0] cnt;
    //integer i,j;
    always@(posedge clk or negedge adc or negedge rst_n) begin
        if(rst_n == `RSTVALID )
	        cnt <= 0;
        else begin
            if(data_e == `DATAVALID)
                cnt <= 0;
            else
                cnt <= cnt + 1;
        end
    end // always

    genvar i,j;
    generate for(i = 0; i < CHANNEL_NUM; i = i + 1) begin : macro_out_loop
        for(j = 0; j < MACRO_NUM; j = j + 1) begin
            always @(posedge clk or negedge rst_n)begin
                if(rst_n == `RSTVALID) begin
                    data_out[i][j] <= 5'b0;
                end else if(cnt == 4'b1111 && macro_e == 1'b1) begin
                    data_out[i][j] <= data_out[i][j] + 1'b1;
                end else begin
                    data_out[i][j] <= data_out[i][j];
                end // if
            end // always
	    end // for j
    end // for i
    endgenerate
endmodule
