`include "alu.svh"

module STUDENT_alu
    (
        input logic [31:0] x,               // 1st input
        input logic [31:0] y,               // 2nd input
        input logic [2:0] op,               // 3-bit op code
        output logic [31:0] z,              // output
        output logic zero, equal, overflow  // flags
    );


    // TODO Part A -- 8:1 mux, AND, ADD (with ripple-carry adder), SUB, flags, SLT
    // mux is at the bottom of the file.

    // submodule outputs
    logic [31:0] z_and; 
    logic [31:0] z_add;
    logic      ovf_add;
    logic [31:0] z_sub;
    logic      ovf_sub;
    logic [31:0] z_slt;
    logic [31:0] z_srl;
    logic [31:0] z_sra;
    logic [31:0] z_sll;
    // AND
    and32 and_unit (.x(x), .y(y), .z(z_and));  // Note the syntax for inputs/outputs to the instantiated module.

    // ADD (RCA)
    // TODO: instantiate adder module
    
    // rca add (.a(x), .b(y), .if_sub(1'b0), .s(z_add), .overflow(ovf_add));
    
    // SUB
    // TODO: instantiate subtractor. Can you think of a way to implement the subtractor by reusing the adder module?
    rca sub (.a(x), .b(y), .if_sub(1'b1), .s(z_sub), .overflow(ovf_sub));
    // SLT
    // TODO: instantiate slt module
    slt32 slt(.x(x), .y(y), .z(z_slt));

    // FLAGS
    // TODO: implement flag logic
    // overflow flag
    logic [2:0] nop;
    not (nop[0], op[0]);
    not (nop[1], op[1]);
    not (nop[2], op[2]);

    logic is_add;
    and (is_add, nop[2], nop[1], op[0]);

    logic is_sub;
    and (is_sub, nop[2], op[1], nop[0]);

    logic ovf_add_op, ovf_sub_op;
    and (ovf_add_op, is_add, ovf_add);
    and (ovf_sub_op, is_sub, ovf_sub);
    or (overflow, ovf_add_op, ovf_sub_op);
    
    // equal flag
    logic [31:0] eq;
    genvar i;
    generate
        for (i=0; i<32; i=i+1) begin : bit_equal
            xnor bit_eq(eq[i], x[i], y[i]);
        end
    endgenerate
    
    and is_eq(equal, eq[0], eq[1], eq[2], eq[3], eq[4], eq[5], eq[6], eq[7], eq[8], eq[9],
              eq[10], eq[11], eq[12], eq[13], eq[14], eq[15], eq[16], eq[17], eq[18], eq[19],
              eq[20], eq[21], eq[22], eq[23], eq[24], eq[25], eq[26], eq[27], eq[28], eq[29],
              eq[30], eq[31]);
    
    // zero flag
    logic [31:0] nz;
    generate
        for (i=0; i<32; i=i+1) begin : not_z
            not not_z(nz[i], z[i]);
        end
    endgenerate
    
    and is_zero(zero, nz[0], nz[1], nz[2], nz[3], nz[4], nz[5], nz[6], nz[7], nz[8], nz[9],
              nz[10], nz[11], nz[12], nz[13], nz[14], nz[15], nz[16], nz[17], nz[18], nz[19],
              nz[20], nz[21], nz[22], nz[23], nz[24], nz[25], nz[26], nz[27], nz[28], nz[29],
              nz[30], nz[31]);
    

    // TODO Part B -- SRL, SRA, SLL, ADD (with carry-lookahead adder)

    // SRL
    // TODO: instantiate srl module
    srl32 srl(.x(x), .sh(y[4:0]),.z(z_srl));
    // SRA
    // TODO: instantiate sra module
    sra32 sra(.x(x), .sh(y[4:0]),.z(z_sra));
    
    // SLL
    // TODO: instantiate sll module
    sll32 sll(.x(x), .sh(y[4:0]),.z(z_sll));
    
    // ADD (CLA)
    // TODO: instantiate cla adder. Comment out the ripple-carry adder instantiation from Part A
    cla32 cla_add(.a(x), .b(y), .cin(1'b0), .s(z_add), .overflow(ovf_add));

    // MUX 8:1 to select the output z from the submodule outputs
    // The code given here only outputs z_and. How can you condition the output based on the operation?
    // Be sure to use the macros (such as `ALU_AND) for the op codes, as defined in alu.svh. 
    mux8_32bit output_mux(.S(op), .D0(z_and), .D1(z_add), .D2(z_sub), .D3(z_slt), .D4(z_srl), .D5(z_sra), .D6(z_sll), .D7(z_cla), .Y(z));

endmodule
