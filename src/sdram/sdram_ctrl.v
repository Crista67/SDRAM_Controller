//============================================================================//
// ****************************** Informations ****************************** //
//============================================================================//
// Auther       :   Crista Y.Z.Li 
// Module name  :   sdram_ctrl
// Project name :   sdram_controller 
// Device       :   Intel Altera EP4CE10F17C8
//                  winbond W9825G6KH-6
// Tool Version :   Quartus Prime 18.0 
//                  ModelsimSE-64 2020.4
// Descreption  :   sdram 控制器控制模块
//
//============================================================================//

module sdram_ctrl (
    // system signals
    input                               clk                 ,
    input                               rstn                ,
    // write module input signals
    input                               wr_req              ,
    input           [23:0]              wr_addr             ,
    input           [9:0]               wr_burst_len        ,
    input           [15:0]              wr_data             ,
    // read module input signals
    input                               rd_req              ,
    input           [23:0]              rd_addr             ,
    input           [9:0]               rd_burst_len        ,
    // init module output signals
    output  wire                        init_end            , 
    // write module output signals
    output  wire                        wr_ack              ,
    // read module output signals
    output  wire    [15:0]              rd_data             ,
    output  wire                        rd_ack              ,
    // sdram interfaces
    output  wire                        sdram_cke           ,
    output  wire                        sdram_cs_n          ,
    output  wire                        sdram_ras_n         ,
    output  wire                        sdram_cas_n         ,
    output  wire                        sdram_we_n          ,
    output  wire    [1:0]               sdram_bank          ,
    output  wire    [12:0]              sdram_addr          ,
    inout   wire    [15:0]              sdram_dq            
);

//============================================================================//
// ********************* parameters & Internal Signals ********************** //
//============================================================================//
// init
wire                [3:0]                       init_cmd                ;
wire                [1:0]                       init_bank               ;
wire                [12:0]                      init_addr               ;
// aref
wire                                            aref_en                 ;
wire                                            aref_req                ;
wire                                            aref_end                ;
wire                [3:0]                       aref_cmd                ;
wire                [1:0]                       aref_bank               ;
wire                [12:0]                      aref_addr               ;
// write
wire                                            wr_en                   ;
wire                                            wr_end                  ;
wire                                            wr_sdram_en             ;
wire                [3:0]                       wr_sdram_cmd            ;
wire                [1:0]                       wr_sdram_bank           ;
wire                [12:0]                      wr_sdram_addr           ;
wire                [15:0]                      wr_sdram_data           ;
// read
wire                                            rd_en                   ;
wire                                            rd_end                  ;
wire                [3:0]                       rd_sdram_cmd            ;
wire                [1:0]                       rd_sdram_bank           ;
wire                [12:0]                      rd_sdram_addr           ;
wire                [15:0]                      rd_sdram_data           ;
//============================================================================//
// ******************************* Main Code ******************************** //
//============================================================================//

sdram_arbit  sdram_arbit_inst (
                .clk                    (clk            ),
                .rstn                   (rstn           ),

                .init_cmd               (init_cmd       ),
                .init_bank              (init_bank      ),
                .init_addr              (init_addr      ),
                .init_end               (init_end       ),

                .aref_req               (aref_req       ),
                .aref_cmd               (aref_cmd       ),
                .aref_bank              (aref_bank      ),
                .aref_addr              (aref_addr      ),
                .aref_end               (aref_end       ),

                .wr_req                 (wr_req         ),
                .wr_cmd                 (wr_sdram_cmd   ),
                .wr_bank                (wr_sdram_bank  ),
                .wr_addr                (wr_sdram_addr  ),
                .wr_end                 (wr_end         ),
                .wr_sdram_en            (wr_sdram_en    ),
                .wr_data                (wr_sdram_data  ),

                .rd_req                 (rd_req         ),
                .rd_cmd                 (rd_sdram_cmd   ),
                .rd_bank                (rd_sdram_bank  ),
                .rd_addr                (rd_sdram_addr  ),
                .rd_end                 (rd_end         ),

                .aref_en                (aref_en        ),
                .wr_en                  (wr_en          ),
                .rd_en                  (rd_en          ),

                .sdram_cke              (sdram_cke      ),
                .sdram_cs_n             (sdram_cs_n     ),
                .sdram_ras_n            (sdram_ras_n    ),
                .sdram_cas_n            (sdram_cas_n    ),
                .sdram_we_n             (sdram_we_n     ),
                .sdram_addr             (sdram_addr     ),
                .sdram_bank             (sdram_bank     ),
                .sdram_dq               (sdram_dq       )
);

sdram_init  sdram_init_inst (
                .clk                    (clk            ),
                .rstn                   (rstn           ),

                .init_cmd               (init_cmd       ),
                .init_bank              (init_bank      ),
                .init_addr              (init_addr      ),
                .init_end               (init_end       )
);

sdram_aref  sdram_aref_inst (
                .clk                    (clk            ),
                .rstn                   (rstn           ),
                .init_end               (init_end       ),
                .aref_en                (aref_en        ),

                .aref_end               (aref_end       ),
                .aref_cmd               (aref_cmd       ),
                .aref_bank              (aref_bank      ),
                .aref_addr              (aref_addr      ),
                .aref_req               (aref_req       )
);

sdram_write  sdram_write_inst (
                .clk                    (clk            ),
                .rstn                   (rstn           ),
                .init_end               (init_end       ),
                .wr_addr                (wr_addr        ),
                .wr_data                (wr_data        ),
                .wr_burst_len           (wr_burst_len   ),
                .wr_en                  (wr_en          ),
                .wr_end                 (wr_end         ),
                .wr_ack                 (wr_ack         ),
                .wr_sdram_data          (wr_sdram_data  ),
                .wr_sdram_en            (wr_sdram_en    ),
                .wr_sdram_cmd           (wr_sdram_cmd   ),
                .wr_sdram_bank          (wr_sdram_bank  ),
                .wr_sdram_addr          (wr_sdram_addr  )
);

sdram_read  sdram_read_inst (
                .clk                    (clk            ),
                .rstn                   (rstn           ),
                .init_end               (init_end       ),
                .rd_addr                (rd_addr        ),
                .rd_sdram_data          (sdram_dq       ),
                .rd_burst_len           (rd_burst_len   ),
                .rd_en                  (rd_en          ),
                .rd_end                 (rd_end         ),
                .rd_ack                 (rd_ack         ),
                .rd_data                (rd_data        ),
                .rd_sdram_cmd           (rd_sdram_cmd   ),
                .rd_sdram_bank          (rd_sdram_bank  ),
                .rd_sdram_addr          (rd_sdram_addr  )
);
endmodule //sdram_ctrl