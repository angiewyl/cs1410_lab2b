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
    genvar i;
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
            


// 4-bit CLA block
module cla4 (
    input  logic [3:0] a,
    input  logic [3:0] b,
    input  logic       cin,
    output logic [3:0] s,
    output logic       P,    // block propagate
    output logic       G,    // block generate
    output logic       cout  // carry-out of this 4-bit block
);
    logic [3:0] p, g;
    logic [4:0] c; 
    
    // bit-level propagate/generate
    genvar i;
    generate
        for (i=0; i<4; i=i+1) begin: gen_pg
            xor(p[i], a[i], b[i]);  
            and(g[i], a[i], b[i]);   
        end
    endgenerate

    assign c[0] = cin;
    // carry lookahead logic for 4 bits
    and(a0, p[0], c[0]); or(c[1], g[0], a0);
    and(a1, p[1], c[1]); or(c[2], g[1], a1);
    and(a2, p[2], c[2]); or(c[3], g[2], a2);
    and(a3, p[3], c[3]); or(c[4], g[3], a3);

    // sum bits: s = p XOR c_in
    xor(s[0], p[0], c[0]);
    xor(s[1], p[1], c[1]);
    xor(s[2], p[2], c[2]);
    xor(s[3], p[3], c[3]);

    // block propagate P
    and(P, p[0], p[1], p[2], p[3]);

    // block generate G 
    logic t0, t1, t2, t3;
    and(t0, p[3], g[2]);
    and(t1, p[3], p[2], g[1]);
    and(t2, p[3], p[2], p[1], g[0]);
    or(G, g[3], t0, t1, t2);

    assign cout = c[4];
endmodule

// 16-bit CLA block made from 4 x 4-bit CLA blocks
module cla16 (
    input  logic [15:0] a,
    input  logic [15:0] b,
    input  logic        cin,
    output logic [15:0] s,
    output logic P, G, cout
);
    // instantiate 8 blocks
    logic [3:0] Pblk, Gblk;
    logic [4:0] c_block;
    assign c_block[0] = cin;
    genvar j;
    generate
        for (j=0; j<4; j=j+1) begin: cla4
            cla4 u_cla4 (
                .a (a[4*j+3 : 4*j]),
                .b (b[4*j+3 : 4*j]),
                .cin (c_block[j]),
                .s (s[4*j+3 : 4*j]),
                .P (Pblk[j]),
                .G (Gblk[j]),
                .cout ()
            );
        end
    endgenerate

    // compute c_block[1]
    and(p0c0, Pblk[0], c_block[0]);
    or(c_block[1], Gblk[0], p0c0);

    // c_block[2] 
    and(p1g0, Pblk[1], Gblk[0]);
    and(p1p0c0, Pblk[1], Pblk[0], c_block[0]);
    or(c_block[2], Gblk[1], p1g0, p1p0c0);

    // c_block[3] 
    and(p2g1, Pblk[2], Gblk[1]);
    and(p2p1g0, Pblk[2], Pblk[1], Gblk[0]);
    and(p2p1p0c0, Pblk[2], Pblk[1], Pblk[0], c_block[0]);
    or(c_block[3], Gblk[2], p2g1, p2p1g0, p2p1p0c0);

    // c_block[4]
    and(p3g2, Pblk[3], Gblk[2]);
    and(p3p2g1, Pblk[3], Pblk[2], Gblk[1]);
    and(p3p2p1g0, Pblk[3], Pblk[2], Pblk[1], Gblk[0]);
    and(p3p2p1p0c0, Pblk[3], Pblk[2], Pblk[1], Pblk[0], c_block[0]);
    or(c_block[4], Gblk[3], p3g2, p3p2g1, p3p2p1g0, p3p2p1p0c0);
    
    and(P, Pblk[0], Pblk[1], Pblk[2], Pblk[3]);
    or(G, Gblk[3], p3g2, p3p2g1, p3p2p1g0);
endmodule

module cla32 (
    input  logic [31:0] a, b,
    input  logic cin,
    output logic [31:0] s,
    output logic overflow
);
    logic [1:0] Pblk, Gblk;
    logic [2:0] Cblk;

    assign Cblk[0] = cin;

    // Two 16-bit CLA blocks
    cla16 first (
        .a   (a[15:0]),
        .b   (b[15:0]),
        .cin (Cblk[0]),
        .s   (s[15:0]),
        .P   (Pblk[0]),
        .G   (Gblk[0]),
        .cout()
    );

    cla16 second (
        .a   (a[31:16]),
        .b   (b[31:16]),
        .cin (Cblk[1]),
        .s   (s[31:16]),
        .P   (Pblk[1]),
        .G   (Gblk[1]),
        .cout()
    );

    // compute carry between 16-bit blocks
    // compute Cblk[1]
    and(p0c0, Pblk[0], Cblk[0]);
    or(Cblk[1], Gblk[0], p0c0);

    // Cblk[2] 
    and(p1g0, Pblk[1], Gblk[0]);
    and(p1p0c0, Pblk[1], Pblk[0], Cblk[0]);
    or(Cblk[2], Gblk[1], p1g0, p1p0c0);

    // Overflow detection (for signed addition)
    xor (overflow, Cblk[2], Cblk[1]);
endmodule

module srl32 (
    input logic [31:0] x,
    input logic [4:0]  sh, 
    output logic [31:0] z
);
    // stage signals
    logic [31:0] stage0, stage1, stage2, stage3, stage4, stage5;
    assign stage0 = x;

    // Stage shift by 16 
    genvar i;
    generate
        for (i=0; i<32; i=i+1) begin: s16
            logic sel, store;
            not (nsel16, sh[4]);
            and (sel, sh[4], 1'b1); 
            if (i+16 < 32) begin
                assign store = stage0[i+16];
            end else begin
                assign store = 1'b0;
            end
            and(a_no16, stage0[i], nsel16);
            and(a_16, store, sel);
            or  (stage1[i], a_no16, a_16);
        end
    endgenerate

    // Stage shift by 8 
    generate
        for (i=0; i<32; i=i+1) begin: s8
            logic sel, store;
            not (nsel8, sh[3]);
            and (sel, sh[3], 1'b1);
            if (i+8 < 32) begin
                assign store = stage1[i+8];
            end else begin
                assign store = 1'b0;
            end
            and(a_no8, stage1[i], nsel8);
            and(a_8, store, sel);
            or  (stage2[i], a_no8, a_8);
        end
    endgenerate

    // Stage shift by 4
    generate
        for (i=0; i<32; i=i+1) begin: s4
            logic sel, store;
            not (nsel4, sh[2]);
            and (sel, sh[2], 1'b1);
            if (i+4 < 32) begin
                assign store = stage2[i+4];
            end else begin
                assign store = 1'b0;
            end
            and(a_no4, stage2[i], nsel4);
            and(a_4, store, sel);
            or  (stage3[i], a_no4, a_4);
        end
    endgenerate

    // Stage shift by 2
    generate
        for (i=0; i<32; i=i+1) begin: s2
            logic sel, store;
            not (nsel2, sh[1]);
            and (sel, sh[1], 1'b1);
            if (i+2 < 32) begin
                assign store = stage3[i+2];
            end else begin
                assign store = 1'b0;
            end
            and(a_no2, stage3[i], nsel2);
            and(a_2, store, sel);
            or  (stage4[i], a_no2, a_2);
        end
    endgenerate
    
    // Stage shift by 1
    generate
        for (i=0; i<32; i=i+1) begin: s1
            logic sel, store;
            not (nsel1, sh[0]);
            and (sel, sh[0], 1'b1);
            if (i+1 < 32) begin
                assign store = stage4[i+1];
            end else begin
                assign store = 1'b0;
            end
            and(a_no1, stage4[i], nsel1);
            and(a_1, store, sel);
            or  (stage5[i], a_no1, a_1);
        end
    endgenerate
    assign z = stage5;
endmodule


module sra32 (
    input logic [31:0] x,
    input logic [4:0]  sh, 
    output logic [31:0] z
);
    // stage signals
    logic [31:0] stage0, stage1, stage2, stage3, stage4, stage5;
    assign stage0 = x;
    logic sign;
    assign sign = x[31];

    // Stage shift by 16 
    genvar i;
    generate
        for (i=0; i<32; i=i+1) begin: s16
            logic sel, store;
            not (nsel16, sh[4]);
            and (sel, sh[4], 1'b1); 
            if (i+16 < 32) begin
                assign store = stage0[i+16];
            end else begin
                assign store = sign;
            end
            and(a_no16, stage0[i], nsel16);
            and(a_16, store, sel);
            or  (stage1[i], a_no16, a_16);
        end
    endgenerate

    // Stage shift by 8 
    generate
        for (i=0; i<32; i=i+1) begin: s8
            logic sel, store;
            not (nsel8, sh[3]);
            and (sel, sh[3], 1'b1);
            if (i+8 < 32) begin
                assign store = stage1[i+8];
            end else begin
                assign store = sign;
            end
            and(a_no8, stage1[i], nsel8);
            and(a_8, store, sel);
            or  (stage2[i], a_no8, a_8);
        end
    endgenerate

    // Stage shift by 4
    generate
        for (i=0; i<32; i=i+1) begin: s4
            logic sel, store;
            not (nsel4, sh[2]);
            and (sel, sh[2], 1'b1);
            if (i+4 < 32) begin
                assign store = stage2[i+4];
            end else begin
                assign store = sign;
            end
            and(a_no4, stage2[i], nsel4);
            and(a_4, store, sel);
            or  (stage3[i], a_no4, a_4);
        end
    endgenerate

    // Stage shift by 2
    generate
        for (i=0; i<32; i=i+1) begin: s2
            logic sel, store;
            not (nsel2, sh[1]);
            and (sel, sh[1], 1'b1);
            if (i+2 < 32) begin
                assign store = stage3[i+2];
            end else begin
                assign store = sign;
            end
            and(a_no2, stage3[i], nsel2);
            and(a_2, store, sel);
            or  (stage4[i], a_no2, a_2);
        end
    endgenerate
    
    // Stage shift by 1
    generate
        for (i=0; i<32; i=i+1) begin: s1
            logic sel, store;
            not (nsel1, sh[0]);
            and (sel, sh[0], 1'b1);
            if (i+1 < 32) begin
                assign store = stage4[i+1];
            end else begin
                assign store = sign;
            end
            and(a_no1, stage4[i], nsel1);
            and(a_1, store, sel);
            or  (stage5[i], a_no1, a_1);
        end
    endgenerate
    assign z = stage5;
endmodule

module sll32 (
    input logic [31:0] x,
    input logic [4:0]  sh, 
    output logic [31:0] z
);
    // stage signals
    logic [31:0] stage0, stage1, stage2, stage3, stage4, stage5;
    assign stage0 = x;

    // Stage shift by 16 
    genvar i;
    generate
        for (i=0; i<32; i=i+1) begin: s16
            logic sel, store;
            not (nsel16, sh[4]);
            and (sel, sh[4], 1'b1); 
            if (i>=16) begin
                assign store = stage0[i-16];
            end else begin
                assign store = 1'b0;
            end
            and(a_no16, stage0[i], nsel16);
            and(a_16, store, sel);
            or  (stage1[i], a_no16, a_16);
        end
    endgenerate

    // Stage shift by 8 
    generate
        for (i=0; i<32; i=i+1) begin: s8
            logic sel, store;
            not (nsel8, sh[3]);
            and (sel, sh[3], 1'b1);
            if (i>=8) begin
                assign store = stage1[i-8];
            end else begin
                assign store = 1'b0;
            end
            and(a_no8, stage1[i], nsel8);
            and(a_8, store, sel);
            or  (stage2[i], a_no8, a_8);
        end
    endgenerate

    // Stage shift by 4
    generate
        for (i=0; i<32; i=i+1) begin: s4
            logic sel, store;
            not (nsel4, sh[2]);
            and (sel, sh[2], 1'b1);
            if (i>=4) begin
                assign store = stage2[i-4];
            end else begin
                assign store = 1'b0;
            end
            and(a_no4, stage2[i], nsel4);
            and(a_4, store, sel);
            or  (stage3[i], a_no4, a_4);
        end
    endgenerate

    // Stage shift by 2
    generate
        for (i=0; i<32; i=i+1) begin: s2
            logic sel, store;
            not (nsel2, sh[1]);
            and (sel, sh[1], 1'b1);
            if (i>=2) begin
                assign store = stage3[i-2];
            end else begin
                assign store = 1'b0;
            end
            and(a_no2, stage3[i], nsel2);
            and(a_2, store, sel);
            or  (stage4[i], a_no2, a_2);
        end
    endgenerate
    
    // Stage shift by 1
    generate
        for (i=0; i<32; i=i+1) begin: s1
            logic sel, store;
            not (nsel1, sh[0]);
            and (sel, sh[0], 1'b1);
            if (i>=1) begin
                assign store = stage4[i-1];
            end else begin
                assign store = 1'b0;
            end
            and(a_no1, stage4[i], nsel1);
            and(a_1, store, sel);
            or  (stage5[i], a_no1, a_1);
        end
    endgenerate
    assign z = stage5;
endmodule
    


