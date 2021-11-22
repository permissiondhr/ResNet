module partial_sum
(
    input  wire                 clk,
    input  wire                 rstn,
    input  wire                 data_in_valid,
    input  wire signed [3:0]    data_in [1:0][63:0],
    output reg                  data_out_valid,
    output reg  signed [7:0]    data_out[63:0]
);

wire signed [3:0]   data_in_tmp[63:0][1:0]
wire signed [7:0]   data_out_tmp[63:0];

genvar i, j;
generate
    for(i = 0; i < 2; i = i + 1) begin
        for(j = 0; j < 64; j = j + 1) begin
            assign data_in_tmp[i][j] = {data_in[i][j][3] : ~data_in[i][j][2:0]};
        end
    end
endgenerate

genvar k;
generate
    for (k = 0; k < 64; k = k + 1) begin
        assign data_out_tmp[k] = data_in_tmp[0][k] + data_in_tmp[1][k];
        always @(posedge clk or negedge rstn) begin
            if(~rstn)
                data_out[k] <= 0;
            else begin
                if(data_in_valid)
                    data_out[k] <= data_out_tmp[k];
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
