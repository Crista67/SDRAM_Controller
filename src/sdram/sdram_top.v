//============================================================================//
// ****************************** Informations ****************************** //
//============================================================================//
// Auther       :   Crista Y.Z.Li 
// Module name  :   sdram_top
// Project name :   sdram_controller 
// Device       :   Intel Altera EP4CE10F17C8
//                  winbond W9825G6KH-6
// Tool Version :   Quartus Prime 18.0 
//                  ModelsimSE-64 2020.4
// Descreption  :   SDRAM Controller Top Module
//
//============================================================================//

module sdram_top (
    input                               clk                 ,
    input                               rstn                ,
    input                               clk_out             ,
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
    
    output  wire    [15:0]              rd_fifo_rd_data     , 
    output  wire    [9:0]               rd_fifo_num         ,

    output  wire                        sdram_clk           ,
    output  wire                        sdram_cke           ,
    output  wire                        sdram_cs_n          ,
    output  wire                        sdram_ras_n         ,
    output  wire                        sdram_cas_n         ,
    output  wire                        sdram_we_n          ,
    output  wire    [1:0]               sdram_bank          ,
    output  wire    [12:0]              sdram_addr          ,
    output  wire    [1:0]               sdram_dqm           ,
    inout   wire    [15:0]              sdram_dq            

);

//============================================================================//
// ********************* parameters & Internal Signals ********************** //
//============================================================================//
wire                                            init_end                ;

wire                                            sdram_wr_ack            ;
wire                                            sdram_wr_req            ;
wire                [23:0]                      sdram_wr_addr           ;
wire                [15:0]                      sdram_wr_data           ;

wire                                            sdram_rd_ack            ;
wire                [15:0]                      sdram_rd_data           ;
wire                                            sdram_rd_req            ;   
wire                [23:0]                      sdram_rd_addr           ;
//============================================================================//
// ******************************* Main Code ******************************** //
//============================================================================//

assign sdram_clk = clk_out;
assign sdram_dqm = 2'b00;

fifo_ctrl  fifo_ctrl_inst (
                // input
                .clk                    (clk            ),
                .rstn                   (rstn           ),
                .init_end               (init_end       ),

                .wr_fifo_wr_clk         (wr_fifo_wr_clk ),
                .wr_fifo_wr_req         (wr_fifo_wr_req ),
                .wr_fifo_wr_data        (wr_fifo_wr_data),
                .sdram_wr_b_addr        (sdram_wr_b_addr),
                .sdram_wr_e_addr        (sdram_wr_e_addr),
                .wr_burst_len           (wr_burst_len   ),
                .wr_rst                 (wr_rst         ),

                .rd_fifo_rd_clk         (rd_fifo_rd_clk ),
                .rd_fifo_rd_req         (rd_fifo_rd_req ),
                .sdram_rd_b_addr        (sdram_rd_b_addr),
                .sdram_rd_e_addr        (sdram_rd_e_addr),
                .rd_burst_len           (rd_burst_len   ),
                .rd_rst                 (rd_rst         ),
                .rd_valid               (rd_valid       ),

                .sdram_wr_ack           (sdram_wr_ack   ),
                .sdram_rd_ack           (sdram_rd_ack   ),
                .sdram_rd_data          (sdram_rd_data  ),
                // output
                .sdram_wr_req           (sdram_wr_req   ),
                .sdram_wr_addr          (sdram_wr_addr  ),
                .sdram_wr_data          (sdram_wr_data  ),

                .rd_fifo_rd_data        (rd_fifo_rd_data),
                .rd_fifo_num            (rd_fifo_num    ),

                .sdram_rd_req           (sdram_rd_req   ),
                .sdram_rd_addr          (sdram_rd_addr  )
);

sdram_ctrl  sdram_ctrl_inst (
                // input
                .clk                    (clk            ),
                .rstn                   (rstn           ),

                .wr_req                 (sdram_wr_req   ),
                .wr_addr                (sdram_wr_addr  ),
                .wr_burst_len           (wr_burst_len   ),
                .wr_data                (sdram_wr_data  ),

                .rd_req                 (sdram_rd_req   ),
                .rd_addr                (sdram_rd_addr  ),
                .rd_burst_len           (rd_burst_len   ),
                // output
                .init_end               (init_end       ),
                .wr_ack                 (sdram_wr_ack   ),

                .rd_data                (sdram_rd_data  ),
                .rd_ack                 (sdram_rd_ack   ),

                .sdram_cke              (sdram_cke      ),
                .sdram_cs_n             (sdram_cs_n     ),
                .sdram_ras_n            (sdram_ras_n    ),
                .sdram_cas_n            (sdram_cas_n    ),
                .sdram_we_n             (sdram_we_n     ),
                .sdram_bank             (sdram_bank     ),
                .sdram_addr             (sdram_addr     ),
                .sdram_dq               (sdram_dq       )
);

endmodule //sdram_top