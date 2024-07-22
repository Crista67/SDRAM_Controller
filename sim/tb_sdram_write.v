`timescale 1ns/1ns

//============================================================================//
// ****************************** Informations ****************************** //
//============================================================================//
// Auther       :   Crista Y.Z.Li 
// Module name  :   tb_sdram_write
// Project name :   sdram_controller 
// Device       :   Intel Altera EP4CE10F17C8
//                  winbond W9825G6KH-6
// Tool Version :   Quartus Prime 18.0 
//                  ModelsimSE-64 2020.4
// Descreption  :   Testbench File for SDRAM Controller Write Module
//
//============================================================================//

module tb_sdram_write ();

reg                                     s_clk               ;
reg                                     s_rstn              ;

wire                                    clk_50m             ;
wire                                    clk_100m            ;
wire                                    clk_100m_s          ;
wire                                    locked              ;
wire                                    rstn                ;

wire        [3:0]                       init_cmd            ;
wire        [1:0]                       init_bank           ;
wire        [12:0]                      init_addr           ;
wire                                    init_end            ;

reg         [15:0]                      wr_data_in          ;
reg                                     wr_en               ;
wire                                    wr_end              ;
wire                                    wr_ack              ;
wire        [15:0]                      wr_sdram_data       ;
wire                                    wr_sdram_en         ;
wire        [3:0]                       wr_sdram_cmd        ;
wire        [1:0]                       wr_sdram_bank       ;
wire        [12:0]                      wr_sdram_addr       ;

wire        [3:0]                       sdram_cmd           ;
wire        [1:0]                       sdram_bank          ;
wire        [12:0]                      sdram_addr          ;
wire        [15:0]                      sdram_data          ;
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

sdram_init  sdram_init_inst(

                .clk                    (clk_100m       ),
                .rstn                   (rstn           ),

                .init_cmd               (init_cmd       ),
                .init_bank              (init_bank      ),
                .init_addr              (init_addr      ),
                .init_end               (init_end       )

);

always @(posedge clk_100m or negedge rstn) begin
    if (rstn == 1'b0)
        wr_data_in      <=      16'd0;
    else if (wr_data_in == 16'd10)
        wr_data_in      <=      16'd0;
    else if (wr_ack == 1'b1)
        wr_data_in      <=      wr_data_in + 1'b1;
    else 
        wr_data_in      <=      wr_data_in;
end

always @(posedge clk_100m or negedge rstn) begin
    if (rstn == 1'b0)
        wr_en       <=      1'b0;
    else if (wr_end == 1'b1)
        wr_en       <=      1'b0;
    else if (init_end == 1'b1)
        wr_en       <=      1'b1;
    else
        wr_en       <=      wr_en;
end

sdram_write  sdram_write_inst (
                .clk                    (clk_100m       ),
                .rstn                   (rstn           ),
                .init_end               (init_end       ),
                .wr_addr                (24'h00_0000    ),
                .wr_data                (wr_data_in     ),
                .wr_burst_len           (10'd10         ),
                .wr_en                  (wr_en          ),

                .wr_end                 (wr_end         ),
                .wr_ack                 (wr_ack         ),
                .wr_sdram_data          (wr_sdram_data  ),
                .wr_sdram_en            (wr_sdram_en    ),
                .wr_sdram_cmd           (wr_sdram_cmd   ),
                .wr_sdram_bank          (wr_sdram_bank  ),
                .wr_sdram_addr          (wr_sdram_addr  )
  );

assign sdram_cmd  = (init_end == 1'b1) ? wr_sdram_cmd  : init_cmd ;
assign sdram_bank = (init_end == 1'b1) ? wr_sdram_bank : init_bank;
assign sdram_addr = (init_end == 1'b1) ? wr_sdram_addr : init_addr;
assign sdram_data = (wr_sdram_en == 1'b1) ? wr_sdram_data : 16'hzzzz;

defparam        sdram_model_plus_inst.addr_bits =	13;
defparam        sdram_model_plus_inst.data_bits =   16;
defparam        sdram_model_plus_inst.col_bits  =	9;
defparam        sdram_model_plus_inst.mem_sizes =	2*1024*1024; 

sdram_model_plus  sdram_model_plus_inst (
                .Dq                     (sdram_data     ),
                .Addr                   (sdram_addr     ),
                .Ba                     (sdram_bank     ),
                .Clk                    (clk_100m_s     ),
                .Cke                    (1'b1           ),
                .Cs_n                   (sdram_cmd[3]   ),
                .Ras_n                  (sdram_cmd[2]   ),
                .Cas_n                  (sdram_cmd[1]   ),
                .We_n                   (sdram_cmd[0]   ),
                .Dqm                    (2'b00          ),
                .Debug                  (1'b1           )
  );

endmodule