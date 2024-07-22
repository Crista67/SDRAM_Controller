`timescale 1ns/1ns

//============================================================================//
// ****************************** Informations ****************************** //
//============================================================================//
// Auther       :   Crista Y.Z.Li 
// Module name  :   tb_sdram_top
// Project name :   sdram_controller 
// Device       :   Intel Altera EP4CE10F17C8
//                  winbond W9825G6KH-6
// Tool Version :   Quartus Prime 18.0 
//                  ModelsimSE-64 2020.4
// Descreption  :   Testbench File for SDRAM Controller Top Module
//
//============================================================================//
module tb_sdram_top;

// Parameters

//Ports
reg                                     s_clk               ;
reg                                     s_rstn              ;

wire                                    clk_50m             ;
wire                                    clk_100m            ;
wire                                    clk_100m_s          ;
wire                                    locked              ;
wire                                    rstn                ;

reg                                     wr_fifo_wr_req      ;
reg         [15:0]                      wr_fifo_wr_data     ;
reg                                     rd_fifo_rd_req      ;
reg                                     rd_valid            ;

wire        [15:0]                      rd_fifo_rd_data     ;
wire        [9:0]                       rd_fifo_num         ;

wire                                    sdram_clk           ;
wire                                    sdram_cke           ;
wire                                    sdram_cs_n          ;
wire                                    sdram_ras_n         ;
wire                                    sdram_cas_n         ;
wire                                    sdram_we_n          ;
wire        [1:0]                       sdram_bank          ;
wire        [12:0]                      sdram_addr          ;
wire        [1:0]                       sdram_dqm           ;
wire        [15:0]                      sdram_dq            ;
//============================================================================//
// ********************************** INIT ********************************** //
//============================================================================//
reg                 [2:0]                       cnt_wr_wait             ;
reg                                             wr_en                   ;
reg                 [3:0]                       cnt_rd_data             ;

initial begin
    s_clk           =       1'b1;
    s_rstn          <=      1'b0;
    # 30
    s_rstn          <=      1'b1;
end

always # 10 s_clk   =       ~ s_clk;

//============================================================================//
// ******************************** instance ******************************** //
//============================================================================//

clk_gen	clk_gen_inst (
                .areset                 (~s_rstn        ),
                .inclk0                 (s_clk          ),
                .c0                     (clk_50m        ),
                .c1                     (clk_100m       ),
                .c2                     (clk_100m_s     ),
                .locked                 (locked         )
);

assign rstn = s_rstn & locked;

always @(posedge clk_50m or negedge rstn) begin
    if (rstn == 1'b0)
        wr_en       <=      1'b1;
    else if (wr_fifo_wr_data == 16'd10)
        wr_en       <=      1'b0;
    else
        wr_en       <=      wr_en;
end

always @(posedge clk_50m or negedge rstn) begin
    if (rstn == 1'b0)
        cnt_wr_wait     <=      3'd0;
    else if (wr_en == 1'b1)
        cnt_wr_wait     <=      cnt_wr_wait + 1'b1;
    else
        cnt_wr_wait     <=      3'd0;
end

always @(posedge clk_50m or negedge rstn) begin
    if (rstn == 1'b0)
        wr_fifo_wr_req        <=      1'b0;
    else if (cnt_wr_wait == 3'd7)
        wr_fifo_wr_req        <=      1'b1;
    else
        wr_fifo_wr_req        <=      1'b0;
end

always @(posedge clk_50m or negedge rstn) begin
    if (rstn == 1'b0)
        wr_fifo_wr_data        <=      1'b0;
    else if (cnt_wr_wait == 3'd7)
        wr_fifo_wr_data        <=      wr_fifo_wr_data + 1'b1;
    else
        wr_fifo_wr_data        <=          wr_fifo_wr_data;
end

always @(posedge clk_50m or negedge rstn) begin
    if (rstn == 1'b0)
        rd_fifo_rd_req       <=      1'b0;
    else if (cnt_rd_data == 4'd9)
        rd_fifo_rd_req       <=      1'b0;
    else if ((wr_en == 1'd0) && (rd_fifo_num >= 10'd10))
        rd_fifo_rd_req       <=      1'b1;
    else
        rd_fifo_rd_req       <=      rd_fifo_rd_req;
end

always @(posedge clk_50m or negedge rstn) begin
    if (rstn == 1'b0)
        cnt_rd_data       <=      4'd0;
    else if (rd_fifo_rd_req == 1'b1)
        cnt_rd_data       <=      cnt_rd_data + 1'b1;
    else
        cnt_rd_data       <=      4'd0;
end

always @(posedge clk_50m or negedge rstn) begin
    if (rstn == 1'b0)
        rd_valid        <=      1'b1;
    else if (rd_fifo_num >= 10'd10)
        rd_valid        <=      1'b0;
end

sdram_top  sdram_top_inst (
                .clk                    (clk_100m       ),
                .rstn                   (rstn           ),
                .clk_out                (clk_100m_s     ),

                .wr_fifo_wr_clk         (clk_50m        ),
                .wr_fifo_wr_req         (wr_fifo_wr_req ),
                .wr_fifo_wr_data        (wr_fifo_wr_data),
                .sdram_wr_b_addr        (24'd0          ),
                .sdram_wr_e_addr        (24'd10         ),
                .wr_burst_len           (10'd10         ),
                .wr_rst                 (~ rstn         ),

                .rd_fifo_rd_clk         (clk_50m        ),
                .rd_fifo_rd_req         (rd_fifo_rd_req ),
                .sdram_rd_b_addr        (24'd0          ),
                .sdram_rd_e_addr        (24'd10         ),
                .rd_burst_len           (10'd10         ),
                .rd_rst                 (~ rstn         ),
                .rd_valid               (rd_valid       ),
                .rd_fifo_rd_data        (rd_fifo_rd_data),
                .rd_fifo_num            (rd_fifo_num    ),

                .sdram_clk              (sdram_clk      ),
                .sdram_cke              (sdram_cke      ),
                .sdram_cs_n             (sdram_cs_n     ),
                .sdram_ras_n            (sdram_ras_n    ),
                .sdram_cas_n            (sdram_cas_n    ),
                .sdram_we_n             (sdram_we_n     ),
                .sdram_bank             (sdram_bank     ),
                .sdram_addr             (sdram_addr     ),
                .sdram_dqm              (sdram_dqm      ),
                .sdram_dq               (sdram_dq       )
);

defparam        sdram_model_plus_inst.addr_bits =	13;
defparam        sdram_model_plus_inst.data_bits =   16;
defparam        sdram_model_plus_inst.col_bits  =	9;
defparam        sdram_model_plus_inst.mem_sizes =	2*1024*1024; 

sdram_model_plus  sdram_model_plus_inst (
                .Clk                    (sdram_clk      ),
                .Cke                    (sdram_cke      ),
                .Cs_n                   (sdram_cs_n     ),
                .Ras_n                  (sdram_ras_n    ),
                .Cas_n                  (sdram_cas_n    ),
                .We_n                   (sdram_we_n     ),
                .Ba                     (sdram_bank     ),
                .Addr                   (sdram_addr     ),
                .Dq                     (sdram_dq       ),
                .Dqm                    (sdram_dqm      ),
                .Debug                  (1'b1           )
  );

endmodule