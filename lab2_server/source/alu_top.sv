//------------------------------------------------------------------------
// Opal Kelly Wrapper
//------------------------------------------------------------------------
`default_nettype none
`timescale 1ns / 1ps


// Definition
module alu_top (
    input  wire [4:0]  okUH,
    output wire [2:0]  okHU,
    inout  wire [31:0] okUHU,
    inout  wire        okAA,
   
    input  wire        mmcm0_clk0,
	output wire [7:0] led
	);



//declare inputs and outputs of uut (ALU)
wire [31:0] x;
wire [31:0] y;
wire [2:0] op;
wire [31:0] z; 
wire zero;
wire equal;
wire overflow;

//instantiate ALU
STUDENT_alu alu_instance
    (
        .x(x),
        .y(y),
        .op(op),
        .z(z), 
        .zero(zero), 
        .equal(equal), 
        .overflow(overflow)
    );
    

// --Wires In and Out
wire [31:0] WireIn00; //for input x
wire [31:0] WireIn01; //for input y
wire [31:0] WireIn02; //for input op

wire [31:0] WireOut20;//for output z 
wire [31:0] WireOut21;//for output flags. The lower 3 bits are overflow, equal, zero. The upper bits are all 0.

assign x = WireIn00;
assign y = WireIn01;
assign op = WireIn02[2:0];
assign WireOut20 = z;
assign WireOut21 = {29'b0,overflow,equal,zero};


// --LED Handler
function [7:0] xem7310_led;
input [7:0] a;
integer i;
begin
	for(i=0; i<8; i=i+1) begin: u
		xem7310_led[i] = (a[i]==1'b1) ? (1'b0) : (1'bz);
	end
end
endfunction

//The first LED displays the output f 
assign led = xem7310_led({5'b0,overflow,equal,zero});



// Opal Kelly Signals
// --OK Library
wire        okClk;
wire[112:0] okHE;
wire[64:0]  okEH;
// --OK Host
wire [65*2-1:0]  okEHx;

okHost okHI(
	.okUH(okUH),
	.okHU(okHU),
	.okUHU(okUHU),
	.okAA(okAA),
	.okClk(okClk),
	.okHE(okHE), 
	.okEH(okEH)
);

okWireOR # (.N(2)) wireOR (okEH, okEHx);

//Wires Ins are the inputs
okWireIn     ep00 (.okHE(okHE),                             .ep_addr(8'h00), .ep_dataout(WireIn00));
okWireIn     ep01 (.okHE(okHE),                             .ep_addr(8'h01), .ep_dataout(WireIn01));
okWireIn     ep02 (.okHE(okHE),                             .ep_addr(8'h02), .ep_dataout(WireIn02));

//Wire Out is the output
okWireOut    ep20 (.okHE(okHE), .okEH(okEHx[ 0*65 +: 65 ]), .ep_addr(8'h20), .ep_datain(WireOut20));
okWireOut    ep21 (.okHE(okHE), .okEH(okEHx[ 1*65 +: 65 ]), .ep_addr(8'h21), .ep_datain(WireOut21));

endmodule
