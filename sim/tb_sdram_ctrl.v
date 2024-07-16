`timescale 1ns/1ns

//============================================================================//
// ****************************** Informations ****************************** //
//============================================================================//
// Auther       :   Crista Y.Z.Li 
// Module name  :   tb_sdram_ctrl
// Project name :   sdram_controller 
// Device       :   Intel Altera EP4CE10F17C8
//                  winbond W9825G6KH-6
// Tool Version :   Quartus Prime 18.0 
//                  ModelsimSE-64 2020.4
// Descreption  :   sdram 控制器控制模块 testbench 仿真文件
//
//============================================================================//

module tb_sdram_ctrl;

reg                                     s_clk               ;
reg                                     s_rstn              ;

wire                                    clk_50m             ;
wire                                    clk_100m            ;
wire                                    clk_100m_s          ;
wire                                    locked              ;
wire                                    rstn                ;

reg                                     wr_req              ;
reg         [15:0]                      wr_data             ;

reg                                     rd_req              ;

wire                                    wr_ack              ;

wire        [15:0]                      rd_data             ;
wire                                    rd_ack              ;

wire                                    sdram_cke           ;
wire                                    sdram_cs_n          ;
wire                                    sdram_ras_n         ;
wire                                    sdram_cas_n         ;
wire                                    sdram_we_n          ;
wire        [1:0]                       sdram_bank          ;
wire        [12:0]                      sdram_addr          ;
wire        [15:0]                      sdram_dq            ;
//============================================================================//
// ********************************** INIT ********************************** //
//============================================================================//
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

always @(posedge clk_100m or negedge rstn) begin
  if (rstn == 1'b0)
      wr_data       <=      16'd0;
  else if (wr_data == 16'd10)
      wr_data       <=      16'd0;
  else if (wr_ack == 1'b1)
      wr_data       <=      wr_data + 1'b1;
  else 
      wr_data       <=      wr_data;
end

always @(posedge clk_100m or negedge rstn) begin
  if (rstn == 1'b0)
      wr_req       <=      1'b1;
  else if (wr_data == 16'b10)
      wr_req      <=      1'b0;
  else
      wr_req      <=      wr_req;
end

always @(posedge clk_100m or negedge rstn) begin
    if (rstn == 1'b0)
        rd_req       <=      1'b0;
    else if (wr_req == 1'b0)
        rd_req       <=      1'b1;
    else
        rd_req       <=      rd_req;
end

sdram_ctrl  sdram_ctrl_inst (
                .clk                    (clk_100m       ),
                .rstn                   (rstn           ),

                .wr_req                 (wr_req         ),
                .wr_addr                (24'h00_0000    ),
                .wr_burst_len           (10'd10         ),
                .wr_data                (wr_data        ),

                .rd_req                 (rd_req         ),
                .rd_addr                (24'h00_0000    ),
                .rd_burst_len           (10'd10         ),

                .wr_ack                 (wr_ack         ),

                .rd_data                (rd_data        ),
                .rd_ack                 (rd_ack         ),

                .sdram_cke              (sdram_cke      ),
                .sdram_cs_n             (sdram_cs_n     ),
                .sdram_ras_n            (sdram_ras_n    ),
                .sdram_cas_n            (sdram_cas_n    ),
                .sdram_we_n             (sdram_we_n     ),
                .sdram_bank             (sdram_bank     ),
                .sdram_addr             (sdram_addr     ),
                .sdram_dq               (sdram_dq       )
);

defparam        sdram_model_plus_inst.addr_bits =	13;
defparam        sdram_model_plus_inst.data_bits =   16;
defparam        sdram_model_plus_inst.col_bits  =	9;
defparam        sdram_model_plus_inst.mem_sizes =	2*1024*1024; 

sdram_model_plus  sdram_model_plus_inst (
                .Dq                     (sdram_dq       ),
                .Addr                   (sdram_addr     ),
                .Ba                     (sdram_bank     ),
                .Clk                    (clk_100m_s     ),
                .Cke                    (sdram_cke      ),
                .Cs_n                   (sdram_cs_n     ),
                .Ras_n                  (sdram_ras_n    ),
                .Cas_n                  (sdram_cas_n    ),
                .We_n                   (sdram_we_n     ),
                .Dqm                    (2'b00          ),
                .Debug                  (1'b1           )
  );


endmodule

