`include "defines.v"
module bn_res_layer7
#(
    parameter FM_DEPTH     = 256,         // Depth of the Feature Map
    parameter CHANNEL_NUM  = 512          // Channel number of Macro
)
(
    input  wire                              clk                          , // System Clock
    input  wire                              rst_n                        , // System Reset, Active LOW
    input  wire                              mode                         , // Mode Switch, LOW -> Reload parameter; HIGH -> Calculate
    input  wire signed [`DATA_WIDTH - 1 : 0] data_in [CHANNEL_NUM - 1 : 0],
    input  wire                              data_e                       ,
    input  wire signed [`PARA_WIDTH - 1 : 0] bn_a    [CHANNEL_NUM - 1 : 0],
    input  wire signed [`PARA_WIDTH - 1 : 0] bn_b    [CHANNEL_NUM - 1 : 0],
    input  wire signed [`DATA_WIDTH - 1 : 0] res     [FM_DEPTH    - 1 : 0],
    output wire signed [`DATA_WIDTH - 1 : 0] data_out[CHANNEL_NUM - 1 : 0],
    output reg                               data_e_out
);

    reg  signed [`DATA_WIDTH * 2 - 1 : 0] data_out_reg[CHANNEL_NUM - 1 : 0];    // register of data_out, 32bit
    wire signed [`DATA_WIDTH - 1 : 0] res_ext[CHANNEL_NUM - 1 : 0]; 

    genvar i;
    generate for(i = 0; i < CHANNEL_NUM; i = i + 1) begin: data_out_reg_loop
        assign res_ext[i] =(i < FM_DEPTH) ? res[i] : res[i - FM_DEPTH];
	    always @(posedge clk or negedge rst_n) begin
            if(rst_n == `RSTVALID) begin    // RESET
                data_out_reg[i] <= 'b0;
            end else if(mode == `CALCULATE && data_e == `DATAVALID) begin   // CALCULATE, y = bn(x) = a*x + b + res
                data_out_reg[i] <= bn_a[i] * data_in[i] + bn_b[i] + res_ext[i];
            end else begin
                data_out_reg[i] <= data_out_reg[i];
            end // if
        end // always
    end // for i
    endgenerate

    always @(posedge clk or negedge rst_n) begin
        if(rst_n == `RSTVALID) begin    // RESET
            data_e_out      <= `DATAINVALID;
        end else if(mode == `CALCULATE && data_e == `DATAVALID) begin   // CALCULATE, y = bn(x) = a*x + b + res
            data_e_out      <= `DATAVALID;
        end else begin
            data_e_out      <= `DATAINVALID;
        end // if
    end // always
    
    genvar j;
    generate
        for(j = 0; j < CHANNEL_NUM; j = j + 1) begin: data_out_loop
            assign data_out[j] = (data_out_reg[j][`DATA_WIDTH * 2 - 1] == 1'b1) ?                               // 
                                    ((data_out_reg[j][`DATA_WIDTH * 2 - 1 : `DATA_WIDTH - 1] == 17'h1ffff) ?    // 
                                        data_out_reg[j][`DATA_WIDTH - 1 : 0] : 16'h8000) :                      // 
                                    ((data_out_reg[j][`DATA_WIDTH * 2 - 1 : `DATA_WIDTH - 1] == 17'h00000) ?    //  
                                        data_out_reg[j][`DATA_WIDTH - 1 : 0] : 16'h7fff) ;                      // 
        end // for i
    endgenerate

endmodule 