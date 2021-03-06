
module dispatcher (
        clk,    // Main clock
        i_mem,  // memory bus in
        i_sel,
        i_sel_t,
        i_enable,
        i_read_buf,
        o_stream // serial output stream
    );

    parameter WL                = 16; // WORD LENGTH in bits
    parameter WORDS_PER_BRICK   = 16;        
    parameter BRICKS_PER_ROW    = 16;
    parameter PARALLEL_WINDOWS  = 16;
    parameter SEL_BITS = 4; //`CLOG2(BRICKS_PER_ROW);    // number of select bits

    parameter BL = WL * WORDS_PER_BRICK;  // BRICK LENGTH in bits
    parameter RL = BL * BRICKS_PER_ROW;   // ROW LENGTH in bits
    parameter SW = WORDS_PER_BRICK * BRICKS_PER_ROW; // STREAM WIDTH in bits

    input                                             clk;
    input       [ RL - 1 : 0 ]                        i_mem;
    input       [ SEL_BITS*PARALLEL_WINDOWS -1 : 0 ]  i_sel; // select the bit to be output
    input       [ SEL_BITS-1:0 ]                      i_sel_t; 
    input       [ PARALLEL_WINDOWS -1 : 0 ]           i_enable; // enable mask for each brick
    input                                             i_read_buf; // select current buffer to read
    output reg  [ SW - 1 : 0 ]                        o_stream;

    wire        [ PARALLEL_WINDOWS * BL - 1 : 0 ]     shuffle_out;
    reg         [ PARALLEL_WINDOWS -1 : 0 ]           b0_enable; // enable mask for each brick
    reg         [ PARALLEL_WINDOWS -1 : 0 ]           b1_enable; // enable mask for each brick
    wire        [ SW - 1 : 0 ]                        b0_out;
    wire        [ SW - 1 : 0 ]                        b1_out;

    shuffler s0 (
        clk,
        i_mem,
        i_sel,
        shuffle_out
      );

    transposer_array b0 (
      clk, 
      b0_enable,
      i_sel_t,
      shuffle_out,
      b0_out
    );

    transposer_array b1 (
      clk, 
      b1_enable,
      i_sel_t,
      shuffle_out,
      b1_out
    );

    always @(*) begin
      if (i_read_buf == 1) begin
        b0_enable = i_enable;
        b1_enable = 0;
        o_stream = b1_out;
      end
      else begin
        b0_enable = 0;
        b1_enable = i_enable;
        o_stream = b0_out;
      end
    end

endmodule
