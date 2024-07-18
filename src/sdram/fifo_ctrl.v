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
// Descreption  :   sdram 控制器 fifo 控制模块
//
//============================================================================//

module fifo_ctrl (
    // input signal
    input                               clk                 ,
    input                               rstn                ,
    input                               init_end            ,
    // write fifo signal
    input                               wr_fifo_wr_clk      ,
    input                               wr_fifo_wr_req      ,
    input           [15:0]              wr_fifo_wr_data     ,
    input           [23:0]              sdram_wr_b_addr     ,
    input           [23:0]              sdram_wr_e_addr     ,
    input           [9:0]               wr_burst_len        ,
    input                               wr_rst              ,
    // read fifo signal
    input                               rd_fifo_rd_clk      ,
    input                               rd_fifo_rd_req      ,
    input           [23:0]              sdram_rd_b_addr     ,
    input           [23:0]              sdram_rd_e_addr     ,
    input           [9:0]               rd_burst_len        ,
    input                               rd_rst              ,
    input                               rd_valid            ,
    // sdram write&read signal
    input                               sdram_wr_ack        ,
    input                               sdram_rd_ack        ,
    input           [15:0]              sdram_rd_data       ,
    // output signal
    // sdram write signal
    output  reg                         sdram_wr_req        ,
    output  reg     [23:0]              sdram_wr_addr       ,
    output  wire    [15:0]              sdram_wr_data       ,
    // read fifo signal
    output  wire    [15:0]              rd_fifo_rd_data     , 
    output  wire    [9:0]               rd_fifo_num         ,
    // sdram read signal
    output  reg                         sdram_rd_req        ,
    output  reg     [23:0]              sdram_rd_addr       
);

//============================================================================//
// ********************* parameters & Internal Signals ********************** //
//============================================================================//

wire                [9:0]                       wr_fifo_num             ;
wire                                            sdram_wr_ack_ne         ;
wire                                            sdram_rd_ack_ne         ;

reg                                             sdram_wr_ack1           ;
reg                                             sdram_rd_ack1           ;


//============================================================================//
// ******************************* Main Code ******************************** //
//============================================================================//

always @(posedge clk or negedge rstn) begin
    if (rstn == 1'b0)
        sdram_wr_ack1       <=      1'b0;
    else
        sdram_wr_ack1       <=      sdram_wr_ack;
end

always @(posedge clk or negedge rstn) begin
    if (rstn == 1'b0)
        sdram_rd_ack1       <=      1'b0;
    else
        sdram_rd_ack1       <=      sdram_rd_ack;
end

assign sdram_wr_ack_ne = (sdram_wr_ack1 & ~sdram_wr_ack);
assign sdram_rd_ack_ne = (sdram_rd_ack1 & ~sdram_rd_ack);

always @(posedge clk or negedge rstn) begin
    if (rstn == 1'b0)
        sdram_wr_addr       <=      24'd0;
    else if (wr_rst == 1'b1)
        sdram_wr_addr       <=      sdram_wr_b_addr;
    else if (sdram_wr_ack_ne == 1'b1) begin
        if (sdram_wr_addr < (sdram_wr_e_addr - wr_burst_len))
            sdram_wr_addr       <=      sdram_wr_addr + wr_burst_len;
        else 
            sdram_wr_addr      <=      sdram_wr_b_addr;
    end
end

always @(posedge clk or negedge rstn) begin
    if (rstn == 1'b0)
        sdram_rd_addr       <=      24'd0;
    else if (rd_rst == 1'b1)
        sdram_rd_addr       <=      sdram_rd_b_addr;
    else if (sdram_rd_ack_ne == 1'b1) begin
        if (sdram_rd_addr < (sdram_rd_e_addr - rd_burst_len))
            sdram_rd_addr       <=      sdram_rd_addr + rd_burst_len;
        else 
            sdram_rd_addr      <=      sdram_rd_b_addr;
    end
end

always @(posedge clk or negedge rstn) begin
    if (rstn == 1'b0) begin
        sdram_wr_req        <=      1'b0;
        sdram_rd_req        <=      1'b0;
    end
    else if (init_end == 1'b1) begin
        if (wr_fifo_num  >= wr_burst_len) begin
            sdram_wr_req        <=      1'b1;
            sdram_rd_req        <=      1'b0;
        end
        else if ((rd_valid == 1'b1) && (rd_fifo_num < rd_burst_len)) begin
            sdram_wr_req        <=      1'b0;
            sdram_rd_req        <=      1'b1;
        end
    end
    else begin
        sdram_wr_req        <=      1'b0;
        sdram_rd_req        <=      1'b1;
    end
end

fifo_data	wr_fifo_data_inst (
                // user interface
                .wrclk                  (wr_fifo_wr_clk ),
                .wrreq                  (wr_fifo_wr_req ),
                .data                   (wr_fifo_wr_data),
                // sdram interface
                .rdclk                  (clk            ),
                .rdreq                  (sdram_wr_ack   ),
                .q                      (sdram_wr_data  ),
                
                .aclr                   (wr_rst || ~rstn),
                .rdusedw                (wr_fifo_num    ),
                .wrusedw                (               )
);

fifo_data	rd_fifo_data_inst (
                // user interface
                .rdclk                  (clk            ),
                .rdreq                  (sdram_rd_ack   ),
                .q                      (sdram_rd_data  ),
                // sdram interface
                .wrclk                  (rd_fifo_rd_clk ),
                .wrreq                  (rd_fifo_rd_req ),
                .data                   (rd_fifo_rd_data),

                .aclr                   (wr_rst || ~rstn),
                .rdusedw                (               ),
                .wrusedw                (rd_fifo_num    )
);


endmodule //fifo_ctrl