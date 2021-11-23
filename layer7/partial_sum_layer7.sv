
`include "defines.v"
`include "partial_sum.sv"
module partial_sum_layer7 
#(
    parameter CHANNEL_NUM  = 512,         // Channel number of Macro
    parameter MACRO_NUM    = 32           // There are 32 Macro in Layer 7, each macro will be used twice
)(
    input  wire                              clk                                                 , // System Clock
    input  wire                              rst_n                                               , // System Reset, Active LOW
    input  wire                              mode                                                , // Mode Switch, LOW -> Reload parameter; HIGH -> Calculate
    input  wire                              data_e                       , // Data Enable From Decoder, Active HIGH.
    input  wire signed [`MACRO_O_DW - 1 : 0] data_in [MACRO_NUM - 1 : 0][63 : 0]      ,
    output reg  signed [`DATA_WIDTH - 1 : 0] data_out[CHANNEL_NUM - 1 : 0], 
    output reg                               data_e_out
);

wire signed [`DATA_WIDTH   - 1 : 0] data_out0[255 : 0];
reg data_e_tmp;
partial_sum ps_layer7_u0
(
    .clk       (clk         ),      // System Clock
    .rst_n     (rst_n       ),      // System Reset, Active LOW
    .mode      (mode        ),      // Mode Switch, LOW -> Reload parameter; HIGH -> Calculate
    .data_e    (data_e),
    .data_in   (data_in[7 : 0]   ),  
    .data_out  (data_out0[63 : 0]),      // Output data from Partail_sum, 16 bit Width, 128
    .data_e_out()       // Ouput of DATA Enabel signal
);

partial_sum ps_layer7_u1
(
    .clk       (clk         ),      // System Clock
    .rst_n     (rst_n       ),      // System Reset, Active LOW
    .mode      (mode        ),      // Mode Switch, LOW -> Reload parameter; HIGH -> Calculate
    .data_e    (data_e),
    .data_in   (data_in[15 : 8]     ),  
    .data_out  (data_out0[127 : 64]),      // Output data from Partail_sum, 16 bit Width, 128
    .data_e_out()       // Ouput of DATA Enabel signal
);

partial_sum ps_layer7_u2
(
    .clk       (clk         ),      // System Clock
    .rst_n     (rst_n       ),      // System Reset, Active LOW
    .mode      (mode        ),      // Mode Switch, LOW -> Reload parameter; HIGH -> Calculate
    .data_e    (data_e),
    .data_in   (data_in[23 : 16]     ),  
    .data_out  (data_out0[191 : 128]),      // Output data from Partail_sum, 16 bit Width, 128
    .data_e_out()       // Ouput of DATA Enabel signal
);

partial_sum ps_layer7_u3
(
    .clk       (clk         ),      // System Clock
    .rst_n     (rst_n       ),      // System Reset, Active LOW
    .mode      (mode        ),      // Mode Switch, LOW -> Reload parameter; HIGH -> Calculate
    .data_e    (data_e),
    .data_in   (data_in[31 : 24]     ),  
    .data_out  (data_out0[255 : 192]),      // Output data from Partail_sum, 16 bit Width, 128
    .data_e_out()       // Ouput of DATA Enabel signal
);
    reg counter;
    always @(posedge clk or negedge rst_n) begin
        if(rst_n == `RSTVALID) begin
            data_e_tmp  <= `DATAINVALID;
        end else if(mode == `CALCULATE && data_e == `DATAVALID) begin
            data_e_tmp  <= `DATAVALID;
        end else begin
            data_e_tmp  <= `DATAINVALID;
        end // if
    end // always

    always @(posedge clk or negedge rst_n) begin
        if(rst_n == `RSTVALID) begin
            counter <= 1'b1;
        end else if(mode == `CALCULATE && data_e_tmp == `DATAVALID) begin
            counter <= counter + 1'b1;
        end else begin
            counter <= counter;
        end // if
    end // always
    
    always @(posedge clk or negedge rst_n) begin
        if(rst_n == `RSTVALID) begin
            for(int j = 0; j < CHANNEL_NUM; j = j + 1)
                data_out[j] <= 16'h0000;
        end else if(mode == `CALCULATE && data_e_tmp == `DATAVALID) begin
            if(counter == 1'b1)
                data_out[255 : 0  ] <= data_out0;
            else
                data_out[511 : 256] <= data_out0;
        end else begin
            for(int j = 0; j < CHANNEL_NUM; j = j + 1)
                data_out[j] <= data_out[j];
        end
    end // always


    always @(posedge clk or negedge rst_n) begin
        if(rst_n == `RSTVALID) begin
            data_e_out  <= `DATAINVALID;
        end else if(mode == `CALCULATE && data_e_tmp == `DATAVALID) begin
            data_e_out  <= (counter == 1'b0) ? `DATAVALID : `DATAINVALID;
        end else begin
            data_e_out  <= `DATAINVALID;
        end
    end // always

endmodule // partial_sum_layer5