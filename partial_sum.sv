module partial_sum
#(
    parameter CHANNEL_NUM  = 128,         // Channel number of Macro
    parameter MACRO_NUM    = 4            // There are 4 macro in layer 3
)
(
    input  wire         clk,
    input  wire         rstn,
    input  wire         data_in_valid,
    input  wire [3:0]   data_in [CHANNEL_NUM-1:0][MACRO_NUM-1:0],
    output reg          data_out_valid,
    output reg  [5:0]  data_out[CHANNEL_NUM-1:0]
);

wire  [5:0]  data_out_tmp[CHANNEL_NUM-1:0];

genvar  i;
generate
    for(i = 0; i < CHANNEL_NUM; i = i + 1) begin
        assign data_out_tmp[i] = {{2{data_in[i][0][3]}}, data_in[i][0]} 
                               + {{2{data_in[i][1][3]}}, data_in[i][1]} 
                               + {{2{data_in[i][2][3]}}, data_in[i][2]} 
                               + {{2{data_in[i][3][3]}}, data_in[i][3]};
        always @(posedge clk or negedge rstn) begin
            if(~rstn)
                data_out[i] <= 5'b0;
            else begin
                if(data_in_valid)
                    data_out[i] <= data_out_tmp[i];
                else ;
            end
        end
    end
endgenerate

always @(posedge clk or negedge rstn) begin
    if(~rstn)
        data_out_valid <= 0;
    else begin
        if(data_in_valid)
            data_out_valid <= 1;
        else
            data_out_valid <= 0;
    end
end
endmodule
