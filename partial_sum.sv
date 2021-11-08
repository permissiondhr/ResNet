module partail_sum_layer4
#(
    parameter CHANNEL_NUM  = 128,         // Channel number of Macro
    parameter MACRO_NUM    = 4            // There are 4 macro in layer 3
)
(
    input  wire [3:0]   data_in [CHANNEL_NUM-1:0][MACRO_NUM-1:0],  
    output wire [15:0]  data_out[CHANNEL_NUM-1:0]
);

wire  [7:0]  data_out_tmp[CHANNEL_NUM-1:0];

genvar  i;
generate
    for(i = 0; i < CHANNEL_NUM; i = i + 1) begin
        assign data_out_tmp[i] =  {{2{data_in[i][0][3]}}, data_in[i][0]} + {{2{data_in[i][1][3]}}, data_in[i][1]} + {{2{data_in[i][2][3]}}, data_in[i][2]} + {{2{data_in[i][3][3]}}, data_in[i][3]};
        assign data_out = {{10{data_out_tmp[i][7]}}, data_out_tmp[i]};
    end
endgenerate

endmodule
