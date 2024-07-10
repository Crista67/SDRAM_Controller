//============================================================================//
// ****************************** Informations ****************************** //
//============================================================================//
// Auther       :   Crista Y.Z.Li 
// Module name  :   sdram_init
// Project name :   sdram_controller 
// Device       :   Intel Altera EP4CE10F17C8
//                  winbond W9825G6KH-6
// Tool Version :   Quartus Prime 18.0 
//                  ModelsimSE-64 2020.4
// Descreption  :   sdram 控制器初始化模块
//
//============================================================================//

module sdram_init (
    input                               clk                 ,
    input                               rstn                ,

    output  reg     [3:0]               init_cmd            ,
    output  reg     [1:0]               init_bank           ,
    output  reg     [12:0]              init_addr           ,
    output  wire                        init_end            

);

//============================================================================//
// ********************* parameters & Internal Signals ********************** //
//============================================================================//

localparam      INIT_IDLE               =       3'b000                  ;
localparam      INIT_PRE                =       3'b001                  ;
localparam      INIT_TRP                =       3'b011                  ;
localparam      INIT_ARE                =       3'b010                  ;
localparam      INIT_TRF                =       3'b110                  ;
localparam      INIT_MRS                =       3'b111                  ;
localparam      INIT_TMRD               =       3'b101                  ;
localparam      INIT_END                =       3'b100                  ;

localparam      WAIT_MAX                =       15'd20_000              ;
localparam      TRP                     =       3'd2                    ;
localparam      TRF                     =       3'd7                    ;
localparam      TMRD                    =       3'd3                    ;

localparam      NOP                     =       4'b0111                 ;
localparam      PRE                     =       4'b0010                 ;
localparam      AREF                    =       4'b0001                 ;
localparam      MRS                     =       4'b0000                 ;


wire                                            wait_end                ;
wire                                            trp_end                 ;
wire                                            trfc_end                ;
wire                                            tmrd_end                ;
reg                 [2:0]                       init_state              ;
reg                 [14:0]                      cnt_200us               ;
reg                 [2:0]                       cnt_clk                 ;
reg                                             cnt_clk_rst             ;
reg                 [3:0]                       cnt_aref                ;

//============================================================================//
// ******************************* Main Code ******************************** //
//============================================================================//

// ----------------------------- state machine ------------------------------ //
always @(posedge clk or negedge rstn) begin
    if (rstn == 1'b0)
        init_state      <=      INIT_IDLE;
    else case (init_state)
        INIT_IDLE :
            if (wait_end == 1'b1)
                init_state  <=  INIT_PRE;
            else
                init_state  <=  init_state;
        INIT_PRE  :
            init_state  <=  INIT_TRP;
        INIT_TRP  :
            if (trp_end == 1'b1)
                init_state  <=  INIT_ARE;
            else
                init_state  <=  init_state;
        INIT_ARE  :
            init_state  <=  INIT_TRF;
        INIT_TRF  :
            if (trfc_end == 1'b1) 
                if (cnt_aref == 4'd8)
                    init_state  <=  INIT_MRS;
                else
                    init_state  <=  INIT_ARE;
            else
                init_state  <=  init_state;
        INIT_MRS  :
            init_state  <=  INIT_TMRD;
        INIT_TMRD :
            if (tmrd_end == 1'b1)
                init_state  <=  INIT_END;
            else
                init_state  <=  init_state;
        INIT_END  :
                init_state  <=  init_state;
        default   :
                init_state  <=  INIT_IDLE;
    endcase
end

always @(posedge clk or negedge rstn) begin
    if (rstn == 1'b0)
        cnt_200us   <=  15'd0;
    else if (cnt_200us == WAIT_MAX)
        cnt_200us   <=  WAIT_MAX;
    else
        cnt_200us   <=  cnt_200us + 1'b1;
end

assign wait_end =   (cnt_200us == (WAIT_MAX - 1'b1)) ? 1'b1 : 1'b0;

always @(posedge clk or negedge rstn) begin
    if (rstn == 1'b0)
        cnt_clk     <=  3'd0;
    else if (cnt_clk_rst == 1'b1)
        cnt_clk     <=  3'd0;
    else
        cnt_clk     <=  cnt_clk + 1'b1;
end

always @( *) begin
    case (init_state)
        INIT_IDLE : cnt_clk_rst     <=  1'b1;
        INIT_TRP  : cnt_clk_rst     <=  (trp_end == 1'b1) ? 1'b1 : 1'b0;
        INIT_TRF  : cnt_clk_rst     <=  (trfc_end == 1'b1) ? 1'b1 : 1'b0;
        INIT_TMRD : cnt_clk_rst     <=  (tmrd_end == 1'b1) ? 1'b1 : 1'b0;
        INIT_END  : cnt_clk_rst     <=  1'b1;
        default   : cnt_clk_rst     <=  1'b0;
    endcase
end

assign trp_end = (cnt_clk == TRP) ? 1'b1 : 1'b0;
assign trfc_end = (cnt_clk == TRF) ? 1'b1 : 1'b0;
assign tmrd_end = (cnt_clk == TMRD) ? 1'b1 : 1'b0;

always @(posedge clk or negedge rstn) begin
    if (rstn == 1'b0)
        cnt_aref    <=  4'd0;
    else if (init_state == INIT_IDLE)
        cnt_aref    <=  4'd0;
    else if (init_state == INIT_ARE)
        cnt_aref    <=  cnt_aref + 1'b1;
    else 
        cnt_aref    <=  cnt_aref;
end

always @(posedge clk or negedge rstn) begin
    if (rstn == 1'b0) begin
        init_cmd    <=      NOP;
        init_bank   <=      2'b11;
        init_addr   <=      13'h1fff;
    end
    else case (init_state)
        INIT_IDLE,INIT_TRP,INIT_TRF,INIT_TMRD,INIT_END :
            begin
                init_cmd    <=      NOP;
                init_bank   <=      2'b11;
                init_addr   <=      13'h1fff;
            end
        INIT_PRE :
            begin
                init_cmd    <=      PRE;
                init_bank   <=      2'b11;
                init_addr   <=      13'h1fff;
            end
        INIT_ARE :
            begin
                init_cmd    <=      AREF;
                init_bank   <=      2'b11;
                init_addr   <=      13'h1fff;
            end
        INIT_MRS :
            begin
                init_cmd    <=      MRS;
                init_bank   <=      2'b00;
                init_addr   <=      {3'b000, 1'b0, 2'b00, 3'b011, 1'b0, 3'b111};
                // 
            end
        default :
            begin
                init_cmd    <=      NOP;
                init_bank   <=      2'b11;
                init_addr   <=      13'h1fff;
            end
    endcase
end

assign init_end = (init_state == INIT_END) ? 1'b1 : 1'b0;

endmodule //sdram_init