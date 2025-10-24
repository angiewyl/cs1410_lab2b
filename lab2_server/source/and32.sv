module and32
    (
        input logic [31:0] x, 
        input logic [31:0] y,
        output logic [31:0] z
    );

    // TODO: Implement the AND gate output. 
    //       Hint: the code is very short, this is 
    //       just to show you how module heirarchy works. 

    // YOUR CODE HERE
    genvar i;
    generate
        for (i=0; i<32; i = i+1) begin: gen_add
            and u_and(z[i], x[i], y[i]);
        end
    endgenerate    
endmodule

module fulladder (
    input logic a, b, cin,
    output logic s, cout
);
    logic ab_xor, ab_and, c;
    xor(ab_xor, a,b);
    xor(s, ab_xor, cin);
    and (ab_and, a, b);
    and (c, ab_xor, cin);
    or (cout, c, ab_and);
endmodule


module rca (
    input logic [31:0] a,
    input logic [31:0] b,
    input logic        if_sub,
    output logic [31:0] s,
    output logic overflow
);

    logic [32:0] carry; // internal carry chain
    logic [31:0] b_mod;
    genvar i;
    generate
        for (i=0; i<32 ; i=i+1) begin:b_invert
            xor xor_b(b_mod[i], b[i], if_sub);
        end
    endgenerate
    
    assign carry[0] = if_sub;
    generate
        for (i = 0; i < 32; i = i + 1) begin : adder_stage
           fulladder fa (
               .a (a[i]),
               .b (b_mod[i]),
               .cin (carry[i]),
               .s (s[i]),
               .cout(carry[i+1])
            );
        end
     endgenerate
     xor ovf(overflow, carry[31], carry[32]);
endmodule

module slt32 (
    input logic [31:0] x,y,
    output logic [31:0] z
);
    logic [31:0] diff;
    logic        overflow;
    logic sign;
    rca sub(.a(x), .b(y), .if_sub(1'b1), .s(diff), .overflow(overflow));
    xor u(sign, diff[31], overflow);
    genvar = i;
    generate
        for (i=0; i<32; i=i+1) begin: fill_slt
            assign z[i] = 1'b0;
        end
    endgenerate
    
    assign z[31] = sign;
endmodule
    

module mux8_32bit (
    input logic [2:0] S,
    input logic [31:0] D0, D1, D2, D3, D4, D5, D6, D7, 
    output logic [31:0] Y
);

    logic [2:0] nS;
    logic [7:0] selection;
    logic [31:0] D_sel [7:0];
    
    not nS0(nS[0], S[0]);
    not nS1(nS[1], S[1]);
    not nS2(nS[2], S[2]);
    
    and u0(selection[0], nS[2], nS[1], nS[0]); // S = 000
    and u1(selection[1], nS[2], nS[1], S[0]); // S = 001
    and u2(selection[2], nS[2], S[1], nS[0]); // S = 010
    and u3(selection[3], nS[2], S[1], S[0]); // S = 011
    and u4(selection[4], S[2], nS[1], nS[0]); // S = 100
    and u5(selection[5], S[2], nS[1], S[0]); // S = 101
    and u6(selection[6], S[2], S[1], nS[0]); // S = 110
    and u7(selection[7], S[2], S[1], S[0]); // S = 111
    
    genvar i;
    generate
        for (i=0; i<32; i=i+1) begin: mux_bits
            and a0(D_sel[0][i], D0[i], selection[0]);
            and a1(D_sel[1][i], D1[i], selection[1]);
            and a2(D_sel[2][i], D2[i], selection[2]);
            and a3(D_sel[3][i], D3[i], selection[3]);
            and a4(D_sel[4][i], D4[i], selection[4]);
            and a5(D_sel[5][i], D5[i], selection[5]);
            and a6(D_sel[6][i], D6[i], selection[6]);
            and a7(D_sel[7][i], D7[i], selection[7]);
            
            or out(Y[i], D_sel[0][i],
                         D_sel[1][i],
                         D_sel[2][i],
                         D_sel[3][i],
                         D_sel[4][i],
                         D_sel[5][i],
                         D_sel[6][i],
                         D_sel[7][i]);
        end
    endgenerate
endmodule
            
        
    


