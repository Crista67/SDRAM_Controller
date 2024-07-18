//============================================================================//
// ****************************** Informations ****************************** //
//============================================================================//
// Auther       :   Crista Y.Z.Li 
// Module name  :   fifo_ctrl
// Project name :   sdram_controller 
// Device       :   Intel Altera EP4CE10F17C8
//                  winbond W9825G6KH-6
// Tool Version :   Quartus Prime 18.0 
//                  ModelsimSE-64 2020.4
// Descreption  :   sdram 控制器 fifo 读模块
//
//============================================================================//

module fifo_read (
    input                               clk                 ,
    input                               rstn                ,
    input           [9:0]               rd_fifo_num         ,
    input           [7:0]               rd_fifo_rd_data     ,
    input           [9:0]               burst_num           ,

    output  reg                         rd_en               , 
    output  reg                         tx_flag             ,
    output  wire    [7:0]     tx_data              
);

//============================================================================//
// ********************* parameters & Internal Signals ********************** //
//============================================================================//
parameter       BAUD_MAX                =       13'd5207                ;
parameter       BAUD_MID                =       13'd2603                ;
parameter       CNT_WAIT_MAX            =       24'd4_999_999           ;

wire                [9:0]                       data_num                ;

reg                                             rd_en1                  ;
reg                 [12:0]                      baud_cnt                ;
reg                                             read_fifo_en            ;
reg                                             rd_flag                 ;
reg                 [9:0]                       cnt_read                ;
reg                 [7:0]                       bit_cnt                 ;
reg                                             bit_flag                ;

//============================================================================//
// ******************************* Main Code ******************************** //
//============================================================================//

always @(posedge clk or negedge rstn) begin
    if (rstn == 1'b0)
        rd_en       <=      1'b0;
    else if (rd_fifo_num == burst_num)
        rd_en       <=      1'b1;
    else if (data_num == burst_num - 2)
        rd_en       <=      1'b0;
end

always @(posedge clk or negedge rstn) begin
    if (rstn == 1'b0)
        rd_en1      <=      1'd0;
    else
        rd_en1      <=      rd_en;
end

always @(posedge clk or negedge rstn) begin
    if (rstn == 1'b0)
        rd_flag     <=      1'b0;
    else if (cnt_read == burst_num)
        rd_flag     <=      1'b0;
    else if (data_num == burst_num)
        rd_flag     <=      1'b1;
end

always @(posedge clk or negedge rstn) begin
    if (rstn == 1'b0)
        baud_cnt        <=      13'd0;
    else if (baud_cnt == BAUD_MAX)
        baud_cnt        <=      13'd0;
    else if (rd_flag == 1'b1)
        baud_cnt        <=      baud_cnt + 1'b1;
end

always @(posedge clk or negedge rstn) begin
    if (rstn == 1'b0)
        bit_flag        <=      1'b0;
    else if (baud_cnt == BAUD_MID)
        bit_flag        <=      1'b1;
    else
        bit_flag        <=      1'b0;
end

always @(posedge clk or negedge rstn) begin
    if (rstn == 1'b0)
        bit_cnt     <=      4'd0;
    else if ((bit_cnt == 4'd9) && (bit_flag == 1'b1))
        bit_cnt     <=      4'd0;
    else if (bit_flag == 1'b1)
        bit_cnt     <=      bit_cnt + 1'b1;
end

always @(posedge clk or negedge rstn) begin
    if (rstn == 1'b0)
        read_fifo_en        <=      1'b0;
    else if ((bit_cnt == 4'd9) && (bit_flag == 1'b1))
        read_fifo_en        <=      1'b1;
    else
        read_fifo_en        <=      1'b0;
end

always @(posedge clk or negedge rstn) begin
    if (rstn == 1'b0)
        cnt_read        <=      10'd0;
    else if (cnt_read == burst_num)
        cnt_read        <=      10'd0;
    else if (read_fifo_en == 1'b1)
        cnt_read        <=      cnt_read + 1'b1;
    else
        cnt_read        <=      cnt_read;
end

always @(posedge clk or negedge rstn) begin
    if (rstn == 1'b0)
        tx_flag     <=      1'b0;
    else
        tx_flag     <=      read_fifo_en;
end

fifo_rd fifo_rd_inst (
                .clock                  (clk            ),
                .data                   (rd_fifo_rd_data),
                .rdreq                  (read_fifo_en   ),
                .wrreq                  (rd_en1         ),

                .q                      (tx_data        ),
                .usedw                  (data_num       )
);
endmodule //fifo_read