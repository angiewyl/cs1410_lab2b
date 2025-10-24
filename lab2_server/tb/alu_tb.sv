`include "alu.svh"

module alu_tb;
	// Inputs
	logic signed [31:0] x;
	logic signed [31:0] y;
	logic [2:0] op;

	// Outputs
	logic signed [31:0] z;
	logic equal;
	logic overflow;
	logic zero;

	// Instantiate the Unit Under Test (UUT)
	STUDENT_alu uut (
		.x, 
		.y, 
		.z, 
		.op, 
		.equal, 
		.overflow, 
		.zero
	);

    int error = 0;
    // TODO: Declare any additional signals here if you need them



    initial begin
        error = 0;
    
        // --- AND ---
        x = 32'hFFFFFFFF; y = 32'h00000000; op = `ALU_AND;     // AND with zero
        #5;
        x = 32'hAAAAAAAA; y = 32'h55555555; op = `ALU_AND;     // bit-pattern test
        #5;
        x = 32'h0; y = 32'h0; op = `ALU_AND; 
        #5;
    
        // --- ADD ---
        x = 32'sh7FFFFFFF; y = 32'sh1; op = `ALU_ADD;           // positive overflow
        #5;
        x = -32'sh80000000; y = -32'sh1; op = `ALU_ADD;         // negative overflow
        #5;
        x = 32'sh40000000; y = 32'sh40000000; op = `ALU_ADD;    // large positive but no overflow
        #5;
        x = -32'sh1; y = 32'sh1; op = `ALU_ADD;                 // zero result
        #5;
    
        // --- SUB ---
        x = 32'sh0; y = 32'sh0; op = `ALU_SUB; #5;
        x = 32'sh7FFFFFFF; y = -32'sh7FFFFFFF; op = `ALU_SUB; #5;  // big positive
        x = -32'sh7FFFFFFF; y = 32'sh7FFFFFFF; op = `ALU_SUB; #5;  // big negative
        x = 32'sh80000000; y = 32'shFFFFFFFF; op = `ALU_SUB; #5;   // -2^31 - (-1)
        x = 32'sh1; y = 32'sh2; op = `ALU_SUB; #5;                  // underflow small

        // --- SLT ---
        x = -32'd1; y = 32'd1; op = `ALU_SLT; #5;                   // true
        x = 32'd1; y = -32'd1; op = `ALU_SLT; #5;                   // false
        x = 32'sh80000000; y = 32'sh7FFFFFFF; op = `ALU_SLT; #5;    // most neg < most pos
        x = 32'sh7FFFFFFF; y = 32'sh80000000; op = `ALU_SLT; #5;    // false
        x = 32'sh5; y = 32'sh5; op = `ALU_SLT; #5;                   // equal case

        // --- SLL ---
        x = 32'h00000001; y = 32'd0; op = `ALU_SLL; #5;             // shift 0
        x = 32'h00000001; y = 32'd1; op = `ALU_SLL; #5;
        x = 32'h00000001; y = 32'd31; op = `ALU_SLL; #5;            // extreme left
        x = 32'hFFFFFFFF; y = 32'd4; op = `ALU_SLL; #5;             // all 1s

        // --- SRL ---
        x = 32'h80000000; y = 32'd1; op = `ALU_SRL; #5;             // MSB shift out
        x = 32'hF0000000; y = 32'd4; op = `ALU_SRL; #5;
        x = 32'h00000001; y = 32'd31; op = `ALU_SRL; #5;            // right to zero
        x = 32'hFFFFFFFF; y = 32'd16; op = `ALU_SRL; #5;            // logical 1?0

        // --- SRA ---
        x = 32'sh80000000; y = 32'd1; op = `ALU_SRA; #5;            // keep sign bit
        x = 32'shFFFFFFFF; y = 32'd4; op = `ALU_SRA; #5;            // all 1s stay 1
        x = 32'sh00000001; y = 32'd1; op = `ALU_SRA; #5;
        x = 32'sh80000000; y = 32'd31; op = `ALU_SRA; #5;           // all sign bits

        // --- Equal/Zero flags ---
        x = 32'd0; y = 32'd0; op = `ALU_ADD; #5;
        x = 32'd0; y = 32'd1; op = `ALU_ADD; #5;
        x = 32'd5; y = 32'd5; op = `ALU_SUB; #5;
    
        // Final report
        $display("Testbench completed with %0d error(s).", error);
        $finish;
    end
    
	

	// an 'always' block is executed whenever any of the variables in the sensitivity
	// list are changed (x, y, or op in this case)
        //** Use this block to check the outputs of your operations against the corresponding SystemVerilog constructs. **//
	always @(x, y, op) begin
		#1;
		case (op)
			`ALU_AND: begin
				if (z !== (x & y)) begin
					$display("ERROR: AND:  op = %b, x = %h, y = %h, z = %h", op, x, y, z);
					error = error + 1;
				end
			end
			`ALU_ADD: begin
			     if (z !== (x + y)) begin
					$display("ERROR: ADD:  op = %b, x = %h, y = %h, z = %h", op, x, y, z);
					error = error + 1;
				end
            end
			`ALU_SUB: begin
			     if (z !== (x - y)) begin
					$display("ERROR: SUB:  op = %b, x = %h, y = %h, z = %h", op, x, y, z);
					error = error + 1;
				end
			end
			`ALU_SLT: begin
			     if (z[31] !== (x < y)) begin
					$display("ERROR: SLT:  op = %b, x = %h, y = %h, z = %h", op, x, y, z);
					error = error + 1;
				end
			end
			`ALU_SRL: begin
			     if (z !== (x >> y)) begin
					$display("ERROR: SRL:  op = %b, x = %h, y = %h, z = %h", op, x, y, z);
					error = error + 1;
				end
			end
			`ALU_SLL: begin
			     if (z !== (x << y)) begin
					$display("ERROR: SLL:  op = %b, x = %h, y = %h, z = %h", op, x, y, z);
					error = error + 1;
				end
			end
			`ALU_SRA: begin
			     if (z !== (x >>> y)) begin
					$display("ERROR: SRA:  op = %b, x = %h, y = %h, z = %h", op, x, y, z);
					error = error + 1;
				end
			end
			default : begin
				// executes if no op codes are matched
			end
		endcase
		
	end
endmodule

