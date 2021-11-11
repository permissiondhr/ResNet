module rsign #(
    parameter FM_DEPTH  = 64,
    parameter CORE_SIZE = 9
) (
    input   wire                clk,
    input   wire                rstn,
    input   wire                data_in_valid,
    input   wire signed [15:0]  para_in [FM_DEPTH-1:0],
    input   wire signed [15:0]  data_in [FM_DEPTH-1:0][CORE_SIZE-1:0],
    output  reg                 data_out[FM_DEPTH-1:0][CORE_SIZE-1:0]
);
genvar i, j;
generate 
    for(i = 0; i < FM_DEPTH; i = i + 1) begin: Rsign_for
        for(j = 0; j< CORE_SIZE; j = j + 1) begin
            always @(posedge clk or negedge rstn) begin
                if(~rstn)
                    data_out[i][j] <= 1'b0;
                else begin
                    if(data_in_valid)
                        data_out[i][j] <= (data_in[i][j] > para_in[i]) ? 1'b1 : 1'b0;
                    else
                        data_out[i][j] <= data_out[i][j];
                end
            end //always
        end // for j
    end // for i
endgenerate // generate

endmodule