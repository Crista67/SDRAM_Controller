//============================================================================//
// ****************************** Informations ****************************** //
//============================================================================//
// Auther       :   Crista Y.Z.Li
// Module name  :   uart_sdram
// Project name :   sdram_controller
// Device       :   Intel Altera EP4CE10F17C8
// Tool Version :   Quartus Prime 18.0
//                  ModelsimSE-64 2020.4
// Descreption  :   rs232 & sdram controller 顶层模块
//
//============================================================================//
module uart_sdram (
    input                               s_clk               ,
    input                               s_rstn              ,
    input                               rs232_rx            ,

    output  wire                        rs232_tx            ,
    
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
// ********************* localparam & Internal Signals ********************** //
//============================================================================//
parameter       DATA_NUM                =       24'd10                  ;
parameter       WAIT_MAX                =       16'd750                 ;
parameter       UART_BPS                =       14'd9600                ;  
parameter       CLK_FREQ                =       26'd50_000_000          ; 

wire                                            clk_50m                 ;
wire                                            clk_100m                ;
wire                                            clk_100m_s              ;
wire                                            locked                  ;
wire								            rstn			        ;

wire                [7:0]                       rx_data                 ;
wire                                            rx_flag                 ;

wire                                            rd_fifo_wr_en           ;
wire                [7:0]                       rd_fifo_wr_data         ;
wire                [9:0]                       rd_fifo_num             ;
reg                                             rd_valid                ;
reg                 [15:0]                      cnt_wait                ;
reg                 [23:0]                      data_num                ;

wire                [7:0]                       rd_fifo_rd_data         ;
wire                                            rd_fifo_rd_en           ;
//============================================================================//
// ******************************* Main Code ******************************** //
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

uart_rx # (
                .UART_BPS               (UART_BPS       ),
                .CLK_FREQ               (CLK_FREQ       )
)   uart_rx_inst (
                .clk                    (clk_50m        ),
                .rstn                   (rstn           ),
                .rs232_rx               (rs232_rx       ),

                .po_data                (rx_data        ),
                .po_flag                (rx_flag        )
  );

always @(posedge clk_50m or negedge s_rstn) begin
    if (s_rstn == 1'b0)
        cnt_wait        <=      16'd0;
    else if (cnt_wait == WAIT_MAX)
        cnt_wait        <=      16'd0;
    else if (data_num == DATA_NUM)
        cnt_wait        <=      cnt_wait + 1'b1;
end

always @(posedge clk_50m or negedge s_rstn) begin
    if (s_rstn == 1'b0)
        data_num        <=      24'd0;
    else if (rd_valid == 1'b1)
        data_num        <=      24'd0;
    else if (rx_flag == 1'b1)
        data_num        <=      data_num + 1'b1;
    else
        data_num        <=      data_num;
end

always @(posedge clk_50m or negedge s_rstn) begin
    if (s_rstn == 1'b0)
        rd_valid        <=      1'b0;
    else if (cnt_wait == WAIT_MAX)
        rd_valid        <=      1'b1;
    else if (rd_fifo_num == DATA_NUM)
        rd_valid        <=      1'b0;
end

sdram_top  sdram_top_inst (
    // Assign values to wr_rst and rd_rst as ~rstn while simulating
                .clk                    (clk_100m       ),
                .rstn                   (rstn           ),
                .clk_out                (clk_100m_s     ),

                .wr_fifo_wr_clk         (clk_50m        ),
                .wr_fifo_wr_req         (rx_flag        ),
                .wr_fifo_wr_data        ({8'h0, rx_data}),
                .sdram_wr_b_addr        (24'h0          ),
                .sdram_wr_e_addr        (DATA_NUM       ),
                .wr_burst_len           (DATA_NUM       ),
                .wr_rst                 (~ rstn         ),

                .rd_fifo_rd_clk         (clk_50m        ),
                .rd_fifo_rd_req         (rd_fifo_wr_en  ),
                .sdram_rd_b_addr        (24'h0          ),
                .sdram_rd_e_addr        (DATA_NUM       ),
                .rd_burst_len           (DATA_NUM       ),
                .rd_rst                 (~ rstn         ),
                .rd_valid               (rd_valid       ),
                .rd_fifo_rd_data        (rd_fifo_wr_data),
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

fifo_read   fifo_read_inst (
                .clk                    (clk_50m        ),
                .rstn                   (s_rstn         ),
                .rd_fifo_num            (rd_fifo_num    ),
                .rd_fifo_rd_data        (rd_fifo_wr_data),
                .burst_num              (DATA_NUM       ),

                .rd_en                  (rd_fifo_wr_en  ),
                .tx_flag                (rd_fifo_rd_en  ),
                .tx_data                (rd_fifo_rd_data)
);

uart_tx # (
                .UART_BPS               (UART_BPS       ),
                .CLK_FREQ               (CLK_FREQ       )
)   uart_tx_inst (
                .clk                    (s_clk          ),
                .rstn                   (s_rstn         ),
                .pi_data                (rd_fifo_rd_data),
                .pi_flag                (rd_fifo_rd_en  ),
                .rs232_tx               (rs232_tx       )
  );
endmodule //uart_sdram
