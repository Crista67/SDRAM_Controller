//============================================================================//
// ****************************** Informations ****************************** //
//============================================================================//
// Auther       :   Crista Y.Z.Li 
// Module name  :   sdram_read
// Project name :   sdram_controller 
// Device       :   Intel Altera EP4CE10F17C8
//                  winbond W9825G6KH-6
// Tool Version :   Quartus Prime 18.0 
//                  ModelsimSE-64 2020.4
// Descreption  :   sdram 控制器读模块
//
//============================================================================//

module sdram_read (
    input                               clk                 ,
    input                               rstn                ,
    input                               init_end            ,
    input           [23:0]              rd_addr             ,
    // rd_addr [23:0] = {rd_bank[1:0], rd_row[8:0], rd_col[12:0]}
    input           [15:0]              rd_sdram_data       ,
    input           [9:0]               rd_burst_len        ,
    input                               rd_en               ,
    
    output  wire                        rd_end              ,
    output  wire                        rd_ack              ,
    output  wire    [15:0]              rd_data             ,
    output  reg     [3:0]               rd_sdram_cmd        ,
    output  reg     [1:0]               rd_sdram_bank       ,
    output  reg     [12:0]              rd_sdram_addr       
);

//============================================================================//
// ********************* parameters & Internal Signals ********************** //
//============================================================================//


localparam      RD_IDLE                 =       4'b0000                 ;
localparam      RD_ACT                  =       4'b0001                 ;
localparam      RD_TRCD                 =       4'b0011                 ;
localparam      RD_REA                  =       4'b0010                 ;
localparam      RD_CL                   =       4'b0110                 ;
localparam      RD_DATA                 =       4'b0111                 ;
localparam      RD_PREC                 =       4'b0101                 ;
localparam      RD_TRP                  =       4'b0100                 ;
localparam      RD_END                  =       4'b1100                 ;


localparam      TRCD                    =       'd2                     ;
localparam      TRD                     =       'd2                     ;
localparam      TCL                     =       'd3                     ;
localparam      TRP                     =       'd2                     ;

localparam      NOP                     =       4'b0111                 ;
localparam      ACT                     =       4'b0011                 ;
localparam      PREC                    =       4'b0010                 ;
localparam      READ                    =       4'b0101                 ;
localparam      BUST                    =       4'b0110                 ;

wire                                            trcd_end                ;
wire                                            tcl_end                 ;
wire                                            trd_end                 ;
wire                                            trp_end                 ;
wire                [9:0]                       bust_max                ;
wire                                            rd_burst_end            ;
reg                 [15:0]                      rd_sdram_data_reg       ;
reg                 [3:0]                       rd_state                ;
reg                 [9:0]                       cnt_clk                 ;
reg                                             cnt_clk_rst             ;

//============================================================================//
// ******************************* Main Code ******************************** //
//============================================================================//

always @(posedge clk or negedge rstn) begin
    if (rstn == 1'b0)
        rd_sdram_data_reg       <=      16'd0;
    else
        rd_sdram_data_reg       <=      rd_sdram_data;
end

always @(posedge clk or negedge rstn) begin
    if (rstn == 1'b0)
        rd_state        <=      RD_IDLE;
    else case (rd_state)
        RD_IDLE :
            if ((init_end == 1'b1) && (rd_en == 1'b1))
                rd_state        <=      RD_ACT;
            else
                rd_state        <=      rd_state;
        RD_ACT  :
            rd_state        <=      RD_TRCD;
        RD_TRCD :
            if (trcd_end == 1'b1)
                rd_state        <=      RD_REA;
            else
                rd_state        <=      rd_state;
        RD_REA  :
            rd_state        <=      RD_CL;
        RD_CL   :
            if (tcl_end == 1'b1)
                rd_state        <=      RD_DATA;
            else
                rd_state        <=      rd_state;
        RD_DATA :
            if (trd_end == 1'b1)
                rd_state        <=      RD_PREC;
            else
                rd_state        <=      rd_state;
        RD_PREC :
            rd_state        <=      RD_TRP;
        RD_TRP  :
            if (trp_end == 1'b1)
                rd_state        <=      RD_END;
            else
                rd_state        <=      rd_state;
        RD_END  :
            rd_state        <=      RD_IDLE;
        default :
            rd_state        <=      rd_state;
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
    case (rd_state)
        RD_IDLE : cnt_clk_rst   <=  1'b1;
        RD_TRCD : cnt_clk_rst   <=  (trcd_end == 1'b1) ? 1'b1 : 1'b0;
        RD_REA  : cnt_clk_rst   <=  1'b1;
        RD_CL   : cnt_clk_rst   <=  (tcl_end == 1'b1) ? 1'b1 : 1'b0;
        RD_DATA : cnt_clk_rst   <=  (trd_end == 1'b1) ? 1'b1 : 1'b0;
        RD_TRP  : cnt_clk_rst   <=  (trp_end == 1'b1) ? 1'b1 : 1'b0;
        RD_END  : cnt_clk_rst   <=  1'b1;
        default : cnt_clk_rst   <=  1'b0;
    endcase
end

assign trcd_end = ((rd_state == RD_TRCD)  && 
                   (cnt_clk == TRCD))  ? 1'b1 : 1'b0;

assign tcl_end  = ((rd_state == RD_CL)  && 
                   (cnt_clk == TCL - 1'b1))  ? 1'b1 : 1'b0;
                   
assign trd_end  = ((rd_state == RD_DATA) && 
                   (cnt_clk == (rd_burst_len - 1'b1 + TCL))) ? 1'b1 : 1'b0;

assign trp_end  = ((rd_state == RD_TRP) && 
                   (cnt_clk == TRP)) ? 1'b1 : 1'b0;

assign bust_max = (rd_burst_len >= (2'd2 + TCL))
                  ? (rd_burst_len - 1'b1 - TCL) : 10'd1;

assign rd_burst_end = ((rd_state == RD_DATA) &&
                       (cnt_clk == bust_max)) ? 1'b1 : 1'b0;

assign rd_ack = ((rd_state == RD_DATA) && 
                 (cnt_clk >= 10'd1) && 
                 (cnt_clk <= rd_burst_len)) ? 1'b1 : 1'b0;

assign rd_end = (rd_state == RD_END) ? 1'b1 : 1'b0;

always @(posedge clk or negedge rstn) begin
    if (rstn == 1'b0) begin
        rd_sdram_cmd    <=      NOP;
        rd_sdram_bank   <=      2'b11;
        rd_sdram_addr   <=      13'h1fff;
    end
    else case (rd_state)
        RD_IDLE,RD_TRCD,RD_TRP :
            begin
                rd_sdram_cmd    <=      NOP;
                rd_sdram_bank   <=      2'b11;
                rd_sdram_addr   <=      13'h1fff;
            end
        RD_ACT :
            begin
                rd_sdram_cmd    <=      ACT;
                rd_sdram_bank   <=      rd_addr[23:22];
                rd_sdram_addr   <=      rd_addr[21:9];
            end
        RD_REA :
            begin
                rd_sdram_cmd    <=      READ;
                rd_sdram_bank   <=      rd_addr[23:22];
                rd_sdram_addr   <=      {4'b0000, rd_addr[8:0]};
            end
        RD_DATA:
            if (rd_burst_end == 1'b1)
                rd_sdram_cmd    <=      BUST;
            else begin
                rd_sdram_cmd    <=      NOP;
                rd_sdram_bank   <=      2'b11;
                rd_sdram_addr   <=      13'h1fff;
            end
        RD_PREC:
            begin
                rd_sdram_cmd    <=      PREC;
                rd_sdram_bank   <=      rd_addr[23:22];
                rd_sdram_addr   <=      13'h0400;
            end
        RD_END :
            begin
                rd_sdram_cmd    <=      NOP;
                rd_sdram_bank   <=      2'b11;
                rd_sdram_addr   <=      13'h1fff;
            end
        default :
            begin
                rd_sdram_cmd    <=      NOP;
                rd_sdram_bank   <=      2'b11;
                rd_sdram_addr   <=      13'h1fff;
            end
    endcase
end

assign rd_data = (rd_ack == 1'b1) ? rd_sdram_data_reg : 16'd0;

endmodule //sdram_read
