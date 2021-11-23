
`include "defines.v"
module partial_sum
(
    input  wire                                clk                     , // System Clock
    input  wire                                rst_n                   , // System Reset, Active LOW
    input  wire                                mode                    ,
    input  wire                                data_e                  , // DATA Enable signal, Active HIGH
    input  wire signed [`MACRO_O_DW   - 1 : 0] data_in [7  : 0][63 : 0],  
    output reg  signed [`DATA_WIDTH   - 1 : 0] data_out[63 : 0]        ,  
    output reg                                 data_e_out                // Ouput of DATA Enabel signal
);
    
    wire [`DECODER_O_DW - 1 : 0] data_de[7 : 0][63 : 0];
    genvar i, j;
    generate
        for(i = 0; i < 8; i = i + 1) begin:data_outi_loop
            for(j = 0; j < 64; j = j + 1) begin:data_outj_loop
                assign data_de[i][j] = {data_in[i][j][3], ~{data_in[i][j][2 : 0]}};
            end // for j 
        end // for i
    endgenerate

    genvar  k;
    generate for(k = 0; k < 64; k = k + 1) begin: data_out_loop
        always @(posedge clk or negedge rst_n) begin
            if(rst_n == `RSTVALID) begin
                data_out[k] <= 16'h0000;
            end else if(mode == `CALCULATE && data_e == `DATAVALID) begin
                data_out[k] <= {{12{data_de[0][k][3]}}, data_de[0][k]}
                            +  {{12{data_de[1][k][3]}}, data_de[1][k]}
                            +  {{12{data_de[2][k][3]}}, data_de[2][k]}
                            +  {{12{data_de[3][k][3]}}, data_de[3][k]}
                            +  {{12{data_de[4][k][3]}}, data_de[4][k]}
                            +  {{12{data_de[5][k][3]}}, data_de[5][k]}
                            +  {{12{data_de[6][k][3]}}, data_de[6][k]}
                            +  {{12{data_de[7][k][3]}}, data_de[7][k]};
            end else begin
                data_out[k] <= data_out[k];
            end // if
        end // always
    end // for i  
    endgenerate // generate    

    always @(posedge clk or negedge rst_n) begin
        if(rst_n == `RSTVALID) begin
            data_e_out  <= `DATAINVALID;
        end else if(mode == `CALCULATE && data_e == `DATAVALID) begin
            data_e_out  <= `DATAVALID;
        end else begin
            data_e_out  <= `DATAINVALID;
        end // if
    end // always

endmodule //module partail_sum_layer4
