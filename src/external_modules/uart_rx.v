
//============================================================================//
// ****************************** Informations ****************************** //
//============================================================================//
// Auther       :   Crista Y.Z.Li 
// Module name  :   uart_rx 
// Project name :   sdram_controller 
// Device       :   Intel Altera EP4CE10F17C8 
// Tool Version :   Quartus Prime 18.0 
//                  ModelsimSE-64 2020.4
// Descreption  :   uart_rx
//
//============================================================================//
module uart_rx #(
    parameter       UART_BPS            =       'd9600      ,
    parameter       CLK_FREQ            =       'd50_000_000
) (
    input                               clk                 ,
    input                               rstn                ,
    input                               rs232_rx            ,

    output  reg     [7:0]               po_data             ,
    output  reg                         po_flag             
);
        
//============================================================================//
// ********************* parameters & Internal Signals ********************** //
//============================================================================//
localparam      BAUD_MAX                =       CLK_FREQ/UART_BPS       ;

reg                                             rx_reg1                 ;
reg                                             rx_reg2                 ;
reg                                             rx_reg3                 ;
reg                                             start_nedge             ;
reg                                             work_en                 ;
reg                 [12:0]                      baud_cnt                ;
reg                                             bit_flag                ;
reg                 [3:0]                       bit_cnt                 ;
reg                 [7:0]                       rx_data                 ;
reg                                             rx_flag                 ;

//============================================================================//
// ******************************* Main Code ******************************** //
//============================================================================//
always @(posedge clk or negedge rstn) begin
    if (rstn == 1'b0)
        rx_reg1 <= 1'b1;
    else
        rx_reg1 <= rs232_rx;
end

always @(posedge clk or negedge rstn) begin
    if (rstn == 1'b0)
        rx_reg2 <= 1'b1;
    else
        rx_reg2 <= rx_reg1;
end

always @(posedge clk or negedge rstn) begin
    if (rstn == 1'b0)
        rx_reg3 <= 1'b1;
    else
        rx_reg3 <= rx_reg2;
end

always @(posedge clk or negedge rstn) begin
    if (rstn == 1'b0)
        start_nedge <= 1'b0;
    else if((~rx_reg2) && (rx_reg3))
        start_nedge <= 1'b1;
    else
        start_nedge <= 1'b0;
end

always @(posedge clk or negedge rstn) begin
    if(rstn == 1'b0)
        work_en <= 1'b0;
    else    if(start_nedge == 1'b1)
        work_en <= 1'b1;
    else    if((bit_cnt == 4'd8) && (bit_flag == 1'b1))
        work_en <= 1'b0;
end

always @(posedge clk or negedge rstn) begin
    if(rstn == 1'b0)
        baud_cnt <= 13'b0;
    else    if((baud_cnt == BAUD_MAX - 1) || (work_en == 1'b0))
        baud_cnt <= 13'b0;
    else    if(work_en == 1'b1)
        baud_cnt <= baud_cnt + 1'b1;
end

always @(posedge clk or negedge rstn) begin
    if(rstn == 1'b0)
        bit_flag <= 1'b0;
    else    if(baud_cnt == BAUD_MAX/2 - 1)
        bit_flag <= 1'b1;
    else
        bit_flag <= 1'b0;
end

always @(posedge clk or negedge rstn) begin
    if(rstn == 1'b0)
        bit_cnt <= 4'b0;
    else if((bit_cnt == 4'd8) && (bit_flag == 1'b1))
        bit_cnt <= 4'b0;
    else if(bit_flag ==1'b1)
         bit_cnt <= bit_cnt + 1'b1;
end

always @(posedge clk or negedge rstn) begin
    if(rstn == 1'b0)
        rx_data <= 8'b0;
    else    if((bit_cnt >= 4'd1)&&(bit_cnt <= 4'd8)&&(bit_flag == 1'b1))
        rx_data <= {rx_reg3, rx_data[7:1]};
end

always@(posedge clk or negedge rstn) begin
    if(rstn == 1'b0)
        rx_flag <= 1'b0;
    else    if((bit_cnt == 4'd8) && (bit_flag == 1'b1))
        rx_flag <= 1'b1;
    else
        rx_flag <= 1'b0;
end

always@(posedge clk or negedge rstn) begin
    if(rstn == 1'b0)
        po_data <= 8'b0;
    else    if(rx_flag == 1'b1)
        po_data <= rx_data;
end

always@(posedge clk or negedge rstn) begin
    if(rstn == 1'b0)
        po_flag <= 1'b0;
    else
        po_flag <= rx_flag;
end

endmodule





