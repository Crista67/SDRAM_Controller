`timescale 1ns/1ns

//============================================================================//
// ****************************** Informations ****************************** //
//============================================================================//
// Auther       :   Crista Y.Z.Li 
// Module name  :   tb_sdram_aref
// Project name :   sdram_controller 
// Device       :   Intel Altera EP4CE10F17C8
//                  winbond W9825G6KH-6
// Tool Version :   Quartus Prime 18.0 
//                  ModelsimSE-64 2020.4
// Descreption  :   Testbench File for SDRAM Controller Auto-Refresh Module
//
//============================================================================//

module tb_sdram_aref ();

reg                                     s_clk               ;
reg                                     s_rstn              ;
reg                                     aref_en             ;

wire                                    clk_50m             ;
wire                                    clk_100m            ;
wire                                    clk_100m_s          ;
wire                                    locked              ;
wire                                    rstn                ;

wire        [3:0]                       init_cmd            ;
wire        [1:0]                       init_bank           ;
wire        [12:0]                      init_addr           ;
wire                                    init_end            ;

wire                                    aref_end            ;
wire        [3:0]                       aref_cmd            ;
wire        [1:0]                       aref_bank           ;
wire        [12:0]                      aref_addr           ;
wire                                    aref_req            ;

wire        [3:0]                       sdram_cmd           ;
wire        [1:0]                       sdram_bank          ;
wire        [12:0]                      sdram_addr          ;

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
        aref_en     <=      1'b0;
    else if ((init_end == 1'b1) && (aref_req == 1'b1))
        aref_en     <=      1'b1;
    else if (aref_end == 1'b1)
        aref_en     <=      1'b0;
end

sdram_init  sdram_init_inst(

                .clk                    (clk_100m       ),
                .rstn                   (rstn           ),

                .init_cmd               (init_cmd       ),
                .init_bank              (init_bank      ),
                .init_addr              (init_addr      ),
                .init_end               (init_end       )

);

sdram_aref  sdram_aref_inst (
                .clk                    (clk_100m       ),
                .rstn                   (rstn           ),
                .init_end               (init_end       ),
                .aref_en                (aref_en        ),

                .aref_end               (aref_end       ),
                .aref_cmd               (aref_cmd       ),
                .aref_bank              (aref_bank      ),
                .aref_addr              (aref_addr      ),
                .aref_req               (aref_req       )
  );

assign sdram_cmd  = (init_end == 1'b1) ? aref_cmd  : init_cmd ;
assign sdram_bank = (init_end == 1'b1) ? aref_bank : init_bank;
assign sdram_addr = (init_end == 1'b1) ? aref_addr : init_addr;

defparam        sdram_model_plus_inst.addr_bits =	13;
defparam        sdram_model_plus_inst.data_bits =   16;
defparam        sdram_model_plus_inst.col_bits  =	9;
defparam        sdram_model_plus_inst.mem_sizes =	2*1024*1024; 

sdram_model_plus  sdram_model_plus_inst (
                .Dq                     (               ),
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