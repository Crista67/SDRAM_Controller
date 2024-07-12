//============================================================================//
// ****************************** Informations ****************************** //
//============================================================================//
// Auther       :   Crista Y.Z.Li 
// Module name  :   sdram_write
// Project name :   sdram_controller 
// Device       :   Intel Altera EP4CE10F17C8
//                  winbond W9825G6KH-6
// Tool Version :   Quartus Prime 18.0 
//                  ModelsimSE-64 2020.4
// Descreption  :   sdram 控制器写模块
//
//============================================================================//

module sdram_write (
    input                               clk                 ,
    input                               rstn                ,
    input                               init_end            ,
    input           [23:0]              wr_addr             ,
    // wr_addr [23:0] = {wr_bank[1:0], wr_row[8:0], wr_col[12:0]}
    input           [15:0]              wr_data             ,
    input           [9:0]               wr_burst_len        ,
    input                               wr_en               ,
    
    output  wire                        wr_end              ,
    output  wire                        wr_ack              ,
    output  wire    [15:0]              wr_sdram_data       ,
    output  reg                         wr_sdram_en         ,
    output  reg     [3:0]               wr_sdram_cmd        ,
    output  reg     [1:0]               wr_sdram_bank       ,
    output  reg     [12:0]              wr_sdram_addr       

);

//============================================================================//
// ********************* parameters & Internal Signals ********************** //
//============================================================================//

localparam      WR_IDLE                 =       3'b000                  ;
localparam      WR_ACT                  =       3'b001                  ;
localparam      WR_TRCD                 =       3'b011                  ;
localparam      WR_WRI                  =       3'b010                  ;
localparam      WR_DATA                 =       3'b110                  ;
localparam      WR_PREC                 =       3'b111                  ;
localparam      WR_TRP                  =       3'b101                  ;
localparam      WR_END                  =       3'b100                  ;

localparam      TRCD                    =       'd2                     ;
localparam      TRP                     =       'd2                     ;

localparam      NOP                     =       4'b0111                 ;
localparam      ACT                     =       4'b0011                 ;
localparam      PREC                    =       4'b0010                 ;
localparam      WRI                     =       4'b0100                 ;
localparam      BUST                    =       4'b0110                 ;

wire                                            trcd_end                ;
wire                                            twr_end                 ;
wire                                            trp_end                 ;
reg                 [2:0]                       wr_state                ;
reg                 [9:0]                       cnt_clk                 ;
reg                                             cnt_clk_rst             ;

//============================================================================//
// ******************************* Main Code ******************************** //
//============================================================================//

always @(posedge clk or negedge rstn) begin
    if (rstn == 1'b0)
        wr_state        <=      WR_IDLE;
    else case (wr_state)
        WR_IDLE :
            if ((init_end == 1'b1) && (wr_en == 1'b1))
                wr_state        <=      WR_ACT;
            else
                wr_state        <=      wr_state;
        WR_ACT  :
            wr_state        <=      WR_TRCD;
        WR_TRCD :
            if (trcd_end == 1'b1)
                wr_state        <=      WR_WRI;
            else
                wr_state        <=      wr_state;
        WR_WRI  :
            wr_state        <=      WR_DATA;
        WR_DATA :
            if (twr_end == 1'b1)
                wr_state        <=      WR_PREC;
            else
                wr_state        <=      wr_state;
        WR_PREC :
            wr_state        <=      WR_TRP;
        WR_TRP  :
            if (trp_end == 1'b1)
                wr_state        <=      WR_END;
            else
                wr_state        <=      wr_state;
        WR_END  :
            wr_state        <=      WR_IDLE;
        default :
            wr_state        <=      wr_state;
    endcase
end

always @(posedge clk or negedge rstn) begin
    if (rstn == 1'b0)
        cnt_clk     <=  10'd0;
    else if (cnt_clk_rst == 1'b1)
        cnt_clk     <=  10'd0;
    else
        cnt_clk     <=  cnt_clk + 1'b1;
end

always @( *) begin
    case (wr_state)
        WR_IDLE : cnt_clk_rst   <=  1'b1;
        WR_TRCD : cnt_clk_rst   <=  (trcd_end == 1'b1) ? 1'b1 : 1'b0;
        WR_WRI  : cnt_clk_rst   <=  1'b1;
        WR_DATA : cnt_clk_rst   <=  (twr_end == 1'b1) ? 1'b1 : 1'b0;
        WR_TRP  : cnt_clk_rst   <=  (trp_end == 1'b1) ? 1'b1 : 1'b0;
        WR_END  : cnt_clk_rst   <=  1'b1;
        default : cnt_clk_rst   <=  1'b0;
    endcase
end

assign trcd_end = ((wr_state == WR_TRCD)  && 
                   (cnt_clk == TRCD))  ? 1'b1 : 1'b0;

assign twr_end  = ((wr_state == WR_DATA)  && 
                   (cnt_clk == (wr_burst_len - 1)))  ? 1'b1 : 1'b0;
                   
assign trp_end  = ((wr_state == WR_TRP) && 
                   (cnt_clk == TRP)) ? 1'b1 : 1'b0;

assign wr_ack = ((wr_state == WR_WRI) || 
                 ((wr_state == WR_DATA) && (cnt_clk <= (wr_burst_len - 2))))
                 ? 1'b1 : 1'b0 ;               

always @(posedge clk or negedge rstn) begin
    if (rstn == 1'b0) begin
        wr_sdram_cmd    <=      NOP;
        wr_sdram_bank   <=      2'b11;
        wr_sdram_addr   <=      13'h1fff;
    end
    else case (wr_state)
        WR_IDLE,WR_TRCD,WR_TRP,WR_END :
            begin
                wr_sdram_cmd    <=      NOP;
                wr_sdram_bank   <=      2'b11;
                wr_sdram_addr   <=      13'h1fff;
            end
        WR_ACT :
            begin
                wr_sdram_cmd    <=      ACT;
                wr_sdram_bank   <=      wr_addr[23:22];
                wr_sdram_addr   <=      wr_addr[21:9];
            end
        WR_WRI :
            begin
                wr_sdram_cmd    <=      WRI;
                wr_sdram_bank   <=      wr_addr[23:22];
                wr_sdram_addr   <=      {4'b0000, wr_addr[8:0]};
            end
        WR_DATA:
            if (twr_end == 1'b1)
                wr_sdram_cmd    <=      BUST;
            else begin
                wr_sdram_cmd    <=      NOP;
                wr_sdram_bank   <=      2'b11;
                wr_sdram_addr   <=      13'h1fff;
            end
        WR_PREC:
            begin
                wr_sdram_cmd    <=      PREC;
                wr_sdram_bank   <=      wr_addr[23:22];
                wr_sdram_addr   <=      13'h0400;
            end
        WR_END :
            begin
                wr_sdram_cmd    <=      NOP;
                wr_sdram_bank   <=      2'b11;
                wr_sdram_addr   <=      13'h1fff;
            end
        default :
            begin
                wr_sdram_cmd    <=      NOP;
                wr_sdram_bank   <=      2'b11;
                wr_sdram_addr   <=      13'h1fff;
            end
    endcase
end

always @(posedge clk or negedge rstn) begin
    if (rstn == 1'b0)
        wr_sdram_en     <=      1'd0;
    else 
        wr_sdram_en     <=      wr_ack;
end

assign wr_sdram_data = (wr_sdram_en == 1'b1) ? wr_data : 16'd0;

assign wr_end = (wr_state == WR_END) ? 1'b1 : 1'b0;


endmodule //sdram_write