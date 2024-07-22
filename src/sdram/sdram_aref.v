//============================================================================//
// ****************************** Informations ****************************** //
//============================================================================//
// Auther       :   Crista Y.Z.Li 
// Module name  :   sdram_aref
// Project name :   sdram_controller 
// Device       :   Intel Altera EP4CE10F17C8
//                  winbond W9825G6KH-6
// Tool Version :   Quartus Prime 18.0 
//                  ModelsimSE-64 2020.4
// Descreption  :   SDRAM Controller Auto-refresh Module
//
//============================================================================//

module sdram_aref (
    input                               clk                 ,
    input                               rstn                ,
    input                               init_end            ,
    input                               aref_en             ,

    output  wire                        aref_end            ,
    output  reg     [3:0]               aref_cmd            ,
    output  reg     [1:0]               aref_bank           ,
    output  reg     [12:0]              aref_addr           ,
    output  reg                         aref_req            


);

//============================================================================//
// ********************* parameters & Internal Signals ********************** //
//============================================================================//
// Maximum Timer Delay Value
// Timing 7.5us (required to be less than 7.8125us)
parameter       CNT_REF_MAX             =       10'd749                 ;
parameter       TRP                     =       3'd2                    ;
parameter       TRF                     =       3'd7                    ;
// states of State Machine
localparam      AREF_IDLE               =       3'b000                  ;
localparam      AREF_PREC               =       3'b001                  ;
localparam      AREF_TRP                =       3'b011                  ;
localparam      AUTO_REF                =       3'b010                  ;
localparam      AREF_TRF                =       3'b110                  ;
localparam      AREF_END                =       3'b111                  ;
// commands
localparam      NOP                     =       4'b0111                 ;
localparam      PREC                    =       4'b0010                 ;
localparam      AREF                    =       4'b0001                 ;

wire                                            aref_ack                ;
wire                                            trp_end                 ;
wire                                            trf_end                 ;

reg                 [9:0]                       cnt_ref                 ;
reg                 [2:0]                       aref_state              ;
reg                 [2:0]                       cnt_clk                 ;
reg                                             cnt_clk_rst             ;

reg                 [1:0]                       cnt_aref                ;

//============================================================================//
// ******************************* Main Code ******************************** //
//============================================================================//
// refresh counter
always @(posedge clk or negedge rstn) begin
    if (rstn == 1'b0)
        cnt_ref     <=      10'd0;
    else if (cnt_ref == CNT_REF_MAX)
        cnt_ref     <=      10'd0;
    else if (init_end == 1'b1)
        cnt_ref     <=      cnt_ref + 1'b1;
end
// request of auto-refresh
always @(posedge clk or negedge rstn) begin
    if (rstn == 1'b0)
        aref_req    <=      1'b0;
    else if (cnt_ref == CNT_REF_MAX - 1'b1)
        aref_req    <=      1'b1;
    else if (aref_ack == 1'b1)
        aref_req    <=      1'b0;
end

assign aref_ack = (aref_state == AREF_PREC) ? 1'b1 : 1'b0;
// ----------------------------- state machine ------------------------------ //
always @(posedge clk or negedge rstn) begin
    if (rstn == 1'b0)
        aref_state  <=      AREF_IDLE;
    else case (aref_state)
        AREF_IDLE :
            if ((init_end == 1'b1) && (aref_en == 1'b1))
                aref_state      <=      AREF_PREC;
            else
                aref_state      <=      aref_state;
        AREF_PREC :
            aref_state      <=      AREF_TRP;
        AREF_TRP  :
            if (trp_end == 1'b1)
                aref_state      <=      AUTO_REF;
            else
                aref_state      <=      aref_state;
        AUTO_REF  :
            aref_state      <=      AREF_TRF;
        AREF_TRF  :
            if (trf_end == 1'b1)
                if (cnt_aref == 2'd2)
                    aref_state      <=      AREF_END;
                else
                    aref_state      <=      AUTO_REF;
            else
                aref_state      <=      aref_state;
        AREF_END  :
            aref_state      <=      AREF_IDLE;
        default   :
            aref_state      <=      AREF_IDLE;
    endcase
end

always @(posedge clk or negedge rstn) begin
    if (rstn == 1'b0)
        cnt_clk     <=  3'd0;
    else if (cnt_clk_rst == 1'b1)
        cnt_clk     <=  3'd0;
    else
        cnt_clk     <=  cnt_clk + 1'b1;
end
// -------------------------------------------------------------------------- //
// counter reset signal
always @( *) begin
    case (aref_state)
        AREF_IDLE : cnt_clk_rst     <=  1'b1;
        AREF_TRP  : cnt_clk_rst     <=  (trp_end == 1'b1) ? 1'b1 : 1'b0;
        AREF_TRF  : cnt_clk_rst     <=  (trf_end == 1'b1) ? 1'b1 : 1'b0;
        AREF_END  : cnt_clk_rst     <=  1'b1;
        default   : cnt_clk_rst     <=  1'b0;
    endcase
end

assign trp_end = ((aref_state == AREF_TRP) && (cnt_clk == TRP)) ? 1'b1 : 1'b0;
assign trf_end = ((aref_state == AREF_TRF) && (cnt_clk == TRF)) ? 1'b1 : 1'b0;
// refresh twice
always @(posedge clk or negedge rstn) begin
    if (rstn == 1'b0)
        cnt_aref    <=  2'd0;
    else if (aref_state == AREF_IDLE)
        cnt_aref    <=  2'd0;
    else if (aref_state == AUTO_REF)
        cnt_aref    <=  cnt_aref + 1'b1;
    else 
        cnt_aref    <=  cnt_aref;
end
// commands
always @(posedge clk or negedge rstn) begin
    if (rstn == 1'b0) begin
        aref_cmd    <=      NOP;
        aref_bank   <=      2'b11;
        aref_addr   <=      13'h1fff;
    end
    else case (aref_state)
        AREF_IDLE,AREF_TRP,AREF_TRF,AREF_END :
            begin
                aref_cmd    <=      NOP;
                aref_bank   <=      2'b11;
                aref_addr   <=      13'h1fff;
            end
        AREF_PREC:
            begin
                aref_cmd    <=      PREC;
                aref_bank   <=      2'b11;
                aref_addr   <=      13'h1fff;
            end
        AUTO_REF :
            begin
                aref_cmd    <=      AREF;
                aref_bank   <=      2'b11;
                aref_addr   <=      13'h1fff;
            end
        default :
            begin
                aref_cmd    <=      NOP;
                aref_bank   <=      2'b11;
                aref_addr   <=      13'h1fff;
            end
    endcase
end
// end flag
assign aref_end = (aref_state == AREF_END) ? 1'b1 : 1'b0;

endmodule //sdram_aref

