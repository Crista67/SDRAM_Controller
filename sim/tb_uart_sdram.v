`timescale 1ns/1ns
//============================================================================//
// ****************************** Informations ****************************** //
//============================================================================//
// Auther       :   Crista Y.Z.Li
// Module name  :   tb_uart_sdram
// Project name :   sdram_controller
// Device       :   Intel Altera EP4CE10F17C8
// Tool Version :   Quartus Prime 18.0
//                  ModelsimSE-64 2020.4
// Descreption  :   Testbench File for SDRAM Controller with UART Communication
//
//============================================================================//


module tb_uart_sdram;

//Ports         
reg                                     s_clk               ;
reg                                     s_rstn              ;

reg                                     rs232_rx            ;
wire                                    rs232_tx            ;

wire                                    sdram_clk           ;
wire                                    sdram_cke           ;
wire                                    sdram_cs_n          ;
wire                                    sdram_ras_n         ;
wire                                    sdram_cas_n         ;
wire                                    sdram_we_n          ;
wire            [1:0]                   sdram_bank          ;
wire            [12:0]                  sdram_addr          ;
wire            [1:0]                   sdram_dqm           ;
wire            [15:0]                  sdram_dq            ;
//============================================================================//
// ********************************** INIT ********************************** //
//============================================================================//
reg             [7:0]                   data_mem [9:0]      ;

initial begin
    s_clk           =       1'b1;
    s_rstn          <=      1'b0;
    # 30
    s_rstn          <=      1'b1;
end

always # 10 s_clk   =       ~ s_clk;

initial
    $readmemh("data_test.txt", data_mem);
    // put "data_test.txt" in "./quartus_prj/Sdram_Controller/simulation/${your_simulation_tool}"

//============================================================================//
// ******************************** instance ******************************** //
//============================================================================//

initial begin
    rs232_rx        <=      1'b1;
    # 200
    rx_byte();
end

task rx_byte() ;
    integer j;
        for (j = 0;j < 10 ;j = j+1)
            rx_bit(data_mem[j]);
endtask

task rx_bit (input [7:0] data);
    integer i;
    for (i = 0; i < 10; i = i+1) begin
        case (i)
            0 : rs232_rx        <=  1'b0;
            1 : rs232_rx        <=  data[0];        
            2 : rs232_rx        <=  data[1];
            3 : rs232_rx        <=  data[2];
            4 : rs232_rx        <=  data[3];
            5 : rs232_rx        <=  data[4];
            6 : rs232_rx        <=  data[5];
            7 : rs232_rx        <=  data[6];
            8 : rs232_rx        <=  data[7];
            9 : rs232_rx        <=  1'b1;
        endcase
        # 1040; // 52.08*20
    end
endtask

defparam        uart_sdram_inst.CLK_FREQ    =   26'd500_000     ;
defparam        uart_sdram_inst.fifo_read_inst.BAUD_MID     = 26;
defparam        uart_sdram_inst.fifo_read_inst.BAUD_MAX     = 52;

uart_sdram  uart_sdram_inst (
                .s_clk                  (s_clk      ),
                .s_rstn                 (s_rstn     ),
                .rs232_rx               (rs232_rx   ),
                .rs232_tx               (rs232_tx   ),
                .sdram_clk              (sdram_clk  ),
                .sdram_cke              (sdram_cke  ),
                .sdram_cs_n             (sdram_cs_n ),
                .sdram_ras_n            (sdram_ras_n),
                .sdram_cas_n            (sdram_cas_n),
                .sdram_we_n             (sdram_we_n ),
                .sdram_bank             (sdram_bank ),
                .sdram_addr             (sdram_addr ),
                .sdram_dqm              (sdram_dqm  ),
                .sdram_dq               (sdram_dq   )
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