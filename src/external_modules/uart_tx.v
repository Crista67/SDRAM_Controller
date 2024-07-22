
//============================================================================//
// ****************************** Informations ****************************** //
//============================================================================//
// Auther       :   Crista Y.Z.Li
// Module name  :   uart_tx
// Project name :   sdram_controller
// Device       :   Intel Altera EP4CE10F17C8
// Tool Version :   Quartus Prime 18.0
//                  ModelsimSE-64 2020.4
// Descreption  :   UART Communication Transmitter Module
//
//============================================================================//
module uart_tx #(
    parameter       UART_BPS            =       'd9600      ,
    parameter       CLK_FREQ            =       'd50_000_000
)(
    input                               clk                 ,
    input                               rstn                ,
    input           [7:0]               pi_data             ,
    input                               pi_flag             ,

    output  reg                         rs232_tx            
);


//============================================================================//
// ********************* parameters & Internal Signals ********************** //
//============================================================================//
localparam      BAUD_MAX                =       CLK_FREQ/UART_BPS       ;

reg                 [12:0]                      baud_cnt                ;
reg                                             bit_flag                ;
reg                 [3:0]                       bit_cnt                 ;
reg                                             work_en                 ;

//============================================================================//
// ******************************* Main Code ******************************** //
//============================================================================//
// working enable signal
always@(posedge clk or negedge rstn) begin
    if(rstn == 1'b0)
        work_en     <=      1'b0;
    else if(pi_flag == 1'b1)
        work_en     <=      1'b1;
    else if((bit_flag == 1'b1) && (bit_cnt == 4'd9))
        work_en     <=      1'b0;
end
// baud rate 9600, 8 bit data
always@(posedge clk or negedge rstn) begin
    if(rstn == 1'b0)
        baud_cnt        <=      13'b0;
    else if((baud_cnt == BAUD_MAX - 1) || (work_en == 1'b0))
        baud_cnt        <=      13'b0;
    else if(work_en == 1'b1)
        baud_cnt        <=      baud_cnt + 1'b1;    
end

always @(posedge clk or negedge rstn) begin
    if(rstn == 1'b0)
        bit_flag        <=      1'b0;
    else if(baud_cnt == 13'd1)
        bit_flag        <=      1'b1;
    else
        bit_flag        <=      1'b0;    
end

always @(posedge clk or negedge rstn) begin
    if(rstn == 1'b0)
        bit_cnt     <=      4'b0;
    else if((bit_flag == 1'b1) && (bit_cnt == 4'd9))
        bit_cnt     <=      4'b0;
    else if((bit_flag == 1'b1) && (work_en == 1'b1))
        bit_cnt     <=      bit_cnt + 1'b1;
end

// Serial Output Data
always@(posedge clk or negedge rstn) begin
        if(rstn == 1'b0)
            rs232_tx    <=      1'b1; //空闲状态时为高电平
        else if(bit_flag == 1'b1)
            case(bit_cnt)
                0       : rs232_tx      <=      1'b0;
                1       : rs232_tx      <=      pi_data[0];
                2       : rs232_tx      <=      pi_data[1];
                3       : rs232_tx      <=      pi_data[2];
                4       : rs232_tx      <=      pi_data[3];
                5       : rs232_tx      <=      pi_data[4];
                6       : rs232_tx      <=      pi_data[5];
                7       : rs232_tx      <=      pi_data[6];
                8       : rs232_tx      <=      pi_data[7];
                9       : rs232_tx      <=      1'b1;
                default : rs232_tx      <=      1'b1;
            endcase
end

endmodule //uart_tx