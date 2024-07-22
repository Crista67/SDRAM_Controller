`timescale 1ns/1ns

//============================================================================//
// ****************************** Informations ****************************** //
//============================================================================//
// Auther       :   Crista Y.Z.Li 
// Module name  :   tb_sdram_init
// Project name :   sdram_controller 
// Device       :   Intel Altera EP4CE10F17C8
//                  winbond W9825G6KH-6
// Tool Version :   Quartus Prime 18.0 
//                  ModelsimSE-64 2020.4
// Descreption  :   Testbench File for SDRAM Controller Initialization Module
//
//============================================================================//

module tb_sdram_init ();

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

defparam        sdram_model_plus_inst.addr_bits =	13;
defparam        sdram_model_plus_inst.data_bits =   16;
defparam        sdram_model_plus_inst.col_bits  =	9;
defparam        sdram_model_plus_inst.mem_sizes =	2*1024*1024; 

sdram_model_plus  sdram_model_plus_inst (
                .Dq                     (               ),
                .Addr                   (init_addr      ),
                .Ba                     (init_bank      ),
                .Clk                    (clk_100m_s     ),
                .Cke                    (1'b1           ),
                .Cs_n                   (init_cmd[3]    ),
                .Ras_n                  (init_cmd[2]    ),
                .Cas_n                  (init_cmd[1]    ),
                .We_n                   (init_cmd[0]    ),
                .Dqm                    (2'b00          ),
                .Debug                  (1'b1           )
  );

endmodule