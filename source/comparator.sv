// The Following code is used to compare 2 8-bit quantites, a and b. The code 
// determines whether or not:
// a is greater than b, gt = 1, lt = 0, eq = 0
// a is less than b, gt = 0, lt = 1, eq = 0
// a is equal to b, gt = 0, lt = 0, eq = 1

module comparator (
	input logic [7:0] a,
	input logic [7:0] b,
	output logic gt,
	output logic lt,
	output logic eq
);
	logic gte;
	logic lte;

	always_comb begin: COMPARATOR
		gt = 1'b0;
		lt = 1'b0;
		eq = 1'b0;
		gte = 1'b0;
		lte = 1'b0;

		if (!(a > b)) begin
			lte = 1'b1;
		end
		if (!(b > a)) begin
			gte = 1'b1;
		end
		if (!(lte == 1'b1)) begin
			gt = 1'b1;
			lt = 1'b0;
			eq = 1'b0;
		end
		else if (!(gte == 1)) begin
			gt = 1'b0;
			lt = 1'b1;
			eq = 1'b0;
		end
		else begin
			gt = 1'b0;
			lt = 1'b0;
			eq = 1'b1;
		end
	end
endmodule

