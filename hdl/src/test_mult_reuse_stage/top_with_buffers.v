
module top_level (
        clk,
        i_nfu1,
        i_partial_sum,
        i_load_partial_sum,
        i_l1_sel_lines,
        i_l2_sel_lines,
        i_extra_l2_bits,
        i_buf_read_addr,
        i_buf_write_addr,
        i_write_en,
        o_l2_bits,
        o_output

    );

    parameter BIT_WIDTH = 16;
    parameter Tn = 16;
    parameter TnxTn = 256;

    parameter OUT_LIMIT = 1;
    parameter IN_LIMIT = 1;

    parameter ADDR_SIZE   = 2;
    parameter NUM_BUFFERS = 1 << ADDR_SIZE;

    parameter L1_SEL_WIDTH = 4;
    parameter L1_NUM_INPUTS = 1 << L1_SEL_WIDTH;

    parameter L2_SEL_WIDTH = 5; // OUT_LIMIT = 1
    //parameter L2_SEL_WIDTH = 6; // OUT_LIMIT = 2


    parameter L2_NUM_INPUTS = 1 << L2_SEL_WIDTH;
    
    parameter EXTRA_L2_BITS = 2;

    //------------ Inputs ------------//
    input clk;
    input i_load_partial_sum;
    input [ (TnxTn)*BIT_WIDTH - 1 : 0 ]                 i_nfu1;
    input [ (Tn*OUT_LIMIT*L1_SEL_WIDTH) - 1 : 0 ]       i_l1_sel_lines;
    input [ (Tn*IN_LIMIT*L2_SEL_WIDTH) - 1 : 0 ]        i_l2_sel_lines;

    input [ (Tn*IN_LIMIT*EXTRA_L2_BITS) - 1 : 0 ]       i_extra_l2_bits;
    output [ (Tn*IN_LIMIT*EXTRA_L2_BITS) - 1 : 0 ]      o_l2_bits;

    input [ ((BIT_WIDTH*Tn) - 1) : 0 ] i_partial_sum; // Partial sum from NBout (nfu2/nfu3 pipe reg)


    input [ (Tn*ADDR_SIZE) - 1 : 0 ]                    i_buf_read_addr;
    input [ (Tn*ADDR_SIZE) - 1 : 0 ]                    i_buf_write_addr;

    input [ Tn-1 : 0 ]                                  i_write_en;

    output [ (Tn*BIT_WIDTH) - 1 : 0 ] o_output;
    
    wire [ (Tn*BIT_WIDTH) - 1 : 0 ] o_nfu2B;

    //wire [ (TnxTn + IN_LIMIT)*BIT_WIDTH - 1 : 0 ]     o_nfu2A;
    wire [ (Tn*IN_LIMIT)*BIT_WIDTH - 1 : 0 ] o_nfu2A;


    // Registers
    //      - nfu1  (From multiplication output)
    //      - L1 and L2 sel lines (For internal muxes)
    //      - Read / write addresses (For the buffers)
    //      - Write enable  (For the buffers)
    //      - Parital sum   (actually NFU-2/NFU-3 pipe register)

    reg [ (TnxTn)*BIT_WIDTH - 1 : 0 ]                 nfu1_reg;
    reg [ (Tn*OUT_LIMIT*L1_SEL_WIDTH) - 1 : 0 ]       l1_sel_lines_reg;
    reg [ (Tn*IN_LIMIT*L2_SEL_WIDTH) - 1 : 0 ]        l2_sel_lines_reg;

    reg [ ((BIT_WIDTH*Tn) - 1) : 0 ]                  partial_sum_reg; // Partial sum from NBout (nfu2/nfu3 pipe reg)


    reg [ (Tn*ADDR_SIZE) - 1 : 0 ]                    buf_read_addr_reg;
    reg [ (Tn*ADDR_SIZE) - 1 : 0 ]                    buf_write_addr_reg;

    reg [ Tn-1 : 0 ]                                  write_en_reg;
    reg [ (Tn*IN_LIMIT*EXTRA_L2_BITS) - 1 : 0 ]       extra_l2_bits_reg;


    nfu_2A #(.OUT_LIMIT(OUT_LIMIT), .IN_LIMIT(IN_LIMIT), .L2_SEL_WIDTH(L2_SEL_WIDTH) ) N0 (
        clk,
        nfu1_reg,
        l1_sel_lines_reg,
        l2_sel_lines_reg,
        buf_read_addr_reg,
        buf_write_addr_reg,
        write_en_reg,
        o_nfu2A
    );

    nfu_2B #(.IN_LIMIT(IN_LIMIT) ) N1 (
       clk,
       nfu1_reg,
       o_nfu2A,
       partial_sum_reg,
       o_nfu2B
    );

    assign o_output = partial_sum_reg;
    assign o_l2_bits = extra_l2_bits_reg;

    // Latch the inputs and outputs for timing constraints
    always @(posedge clk) begin
        nfu1_reg <= i_nfu1;
        l1_sel_lines_reg <= i_l1_sel_lines;
        l2_sel_lines_reg <= i_l2_sel_lines;
   
        buf_read_addr_reg <= i_buf_read_addr;
        buf_write_addr_reg <= i_buf_write_addr;

        write_en_reg <= i_write_en;

        if(i_load_partial_sum == 1) begin
            partial_sum_reg <= i_partial_sum;
        end else begin
            partial_sum_reg <= o_nfu2B;
        end

        extra_l2_bits_reg <= i_extra_l2_bits;
end


endmodule



module top_level_base (
        clk,
        i_nfu1,
        i_partial_sum,
        i_load_partial_sum,
        o_output
    );

    parameter BIT_WIDTH = 16;
    parameter Tn = 16;
    parameter TnxTn = 256;

    //------------ Inputs ------------//
    input clk;
    input i_load_partial_sum;
    input [ (TnxTn)*BIT_WIDTH - 1 : 0 ]                 i_nfu1;
    input [ ((BIT_WIDTH*Tn) - 1) : 0 ] i_partial_sum; // Partial sum from NBout (nfu2/nfu3 pipe reg)

    output [ (Tn*BIT_WIDTH) - 1 : 0 ] o_output;
    
    wire [ (Tn*BIT_WIDTH) - 1 : 0 ] o_nfu2B;

    // Registers
    //      - nfu1  (From multiplication output)
    //      - Parital sum   (actually NFU-2/NFU-3 pipe register)

    reg [ (TnxTn)*BIT_WIDTH - 1 : 0 ]                 nfu1_reg;
    reg [ ((BIT_WIDTH*Tn) - 1) : 0 ]                  partial_sum_reg; // Partial sum from NBout (nfu2/nfu3 pipe reg)

    nfu_2 N0 (
        clk,
        nfu1_reg,
        partial_sum_reg,
        o_nfu2B
    );

    assign o_output = partial_sum_reg;

    // Latch the inputs and outputs for timing constraints
    always @(posedge clk) begin
        nfu1_reg <= i_nfu1;
   
        if(i_load_partial_sum == 1) begin
            partial_sum_reg <= i_partial_sum;
        end else begin
            partial_sum_reg <= o_nfu2B;
        end
    end


endmodule

