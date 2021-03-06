

module m_addr (
        i_A,
        i_B,
        o_C
    );
    
    parameter N = 16;

    input [N-1:0] i_A, i_B;
    output [N-1:0] o_C;


    //------------ Change adder implementation here ----------------//
    // Integer add (Approx. area to a fixed-point adder)
    assign o_C = {1'b0,i_A} + {1'b0,i_B};

endmodule
