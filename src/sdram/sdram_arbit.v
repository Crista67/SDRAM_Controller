//============================================================================//
// ****************************** Informations ****************************** //
//============================================================================//
// Auther       :   Crista Y.Z.Li 
// Module name  :   sdram_arbit
// Project name :   sdram_controller 
// Device       :   Intel Altera EP4CE10F17C8
//                  winbond W9825G6KH-6
// Tool Version :   Quartus Prime 18.0 
//                  ModelsimSE-64 2020.4
// Descreption  :   sdram 控制器仲裁模块
//
//============================================================================//
module sdram_arbit (
    input                               clk                 ,
    input                               rstn                ,

    input           [3:0]               init_cmd            ,
    input           [1:0]               init_bank           ,
    input           [12:0]              init_addr           ,
    input                               init_end            ,

    input                               aref_req            ,
    input           [3:0]               aref_cmd            ,
    input           [1:0]               aref_bank           ,
    input           [12:0]              aref_addr           ,
    input                               aref_end            ,

    input                               wr_req              ,
    input           [3:0]               wr_cmd              ,
    input           [1:0]               wr_bank             ,
    input           [12:0]              wr_addr             ,
    input                               wr_end              ,
    input                               wr_sdram_en         ,
    input           [15:0]              wr_data             ,

    input                               rd_req              ,
    input           [3:0]               rd_cmd              ,
    input           [1:0]               rd_bank             ,
    input           [12:0]              rd_addr             ,
    input                               rd_end              ,

    output  reg                         aref_en             ,
    output  reg                         wr_en               ,
    output  reg                         rd_en               ,

    output  wire                        sdram_cke           , 
    output  wire                        sdram_cs_n          , 
    output  wire                        sdram_ras_n         , 
    output  wire                        sdram_cas_n         , 
    output  wire                        sdram_we_n          , 
    output  reg     [12:0]              sdram_addr          , 
    output  reg     [1:0]               sdram_bank          , 
    
    inout   wire    [15:0]              sdram_dq            
);

//============================================================================//
// ********************* parameters & Internal Signals ********************** //
//============================================================================//
localparam      IDLE                    =       5'b0_0001               ;
localparam      ARBIT                   =       5'b0_0010               ;
localparam      AREF                    =       5'b0_0100               ;
localparam      WRITE                   =       5'b0_1000               ;
localparam      READ                    =       5'b1_0000               ;

localparam      NOP                     =       4'b0111                 ;

reg                 [4:0]                       state                   ;
reg                 [3:0]                       sdram_cmd               ;

//============================================================================//
// ******************************* Main Code ******************************** //
//============================================================================//

always @(posedge clk or negedge rstn) begin
    if (rstn == 1'b0)
        state       <=      IDLE;
    else case (state)
            IDLE  :
                if (init_end == 1'b1)
                    state       <=      ARBIT;
                else
                    state       <=      state;
            ARBIT :
                if (aref_req == 1'b1)
                    state       <=      AREF;
                else if (wr_req == 1'b1)
                    state       <=      WRITE;
                else if (rd_req == 1'b1)
                    state       <=      READ;
                else
                    state       <=      state;
            AREF  :
                if (aref_end == 1'b1)
                    state       <=      ARBIT;
                else
                    state       <=      state;
            WRITE :
                if (wr_end == 1'b1)
                    state       <=      ARBIT;
                else
                    state       <=      state;
            READ  :
                if (rd_end == 1'b1)
                    state       <=      ARBIT;
                else
                    state       <=      state;
            default :
                state       <=      IDLE;
    endcase
end

always @( *) begin
    case (state)
        IDLE  : begin
            sdram_cmd       <=      init_cmd;
            sdram_bank      <=      init_bank;
            sdram_addr      <=      init_addr;
        end
        AREF  : begin
            sdram_cmd       <=      aref_cmd;
            sdram_bank      <=      aref_bank;
            sdram_addr      <=      aref_addr;
        end
        WRITE : begin
            sdram_cmd       <=      wr_cmd;
            sdram_bank      <=      wr_bank;
            sdram_addr      <=      wr_addr;
        end
        READ  : begin
            sdram_cmd       <=      rd_cmd;
            sdram_bank      <=      rd_bank;
            sdram_addr      <=      rd_addr;
        end
        default : begin
            sdram_cmd       <=      NOP;
            sdram_bank      <=      2'b11;
            sdram_addr      <=      13'h1fff;            
        end
    endcase
end

always @(posedge clk or negedge rstn) begin
    if (rstn == 1'b0)
        aref_en     <=      1'b0;
    else if ((state == ARBIT) && (aref_req == 1'b1))
        aref_en     <=      1'b1;
    else if (aref_end == 1'b1)
        aref_en     <=      1'b0;
end

always @(posedge clk or negedge rstn) begin
    if (rstn == 1'b0)
        wr_en       <=      1'b0;
    else if ((state == ARBIT) && (aref_req == 1'b0) && (wr_req == 1'b1))
        wr_en       <=      1'b1;
    else if (aref_end == 1'b1)
        wr_en       <=      1'b0;
end

always @(posedge clk or negedge rstn) begin
    if (rstn == 1'b0)
        rd_en       <=      1'b0;
    else if ((state == ARBIT) && (aref_req == 1'b0) && (rd_req == 1'b1))
        rd_en       <=      1'b1;
    else if (aref_end == 1'b1)
        rd_en       <=      1'b0;
end

assign {sdram_cs_n, sdram_ras_n, sdram_cas_n, sdram_we_n} = sdram_cmd;

assign sdram_cke = 1'b1;

assign sdram_dq = (wr_sdram_en == 1'b1) ? wr_data : 16'hzzzz;

endmodule //sdram_arbit