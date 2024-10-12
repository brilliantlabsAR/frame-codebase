////////////////////////////////////////////////////////////////////////////////
//
// Filename: 	clkswitch.v
//
// Project:	Formal methods example
//
// Purpose:	This file shows an example asynchronous clock switching
//		design.  It is offered here as an example of how an
//	asynchronous design might be formally verified using the open source
//	SymbiYosys tool.
//
// Creator:	Dan Gisselquist, Ph.D.
//		Gisselquist Technology, LLC
//
////////////////////////////////////////////////////////////////////////////////
//
// Copyright (C) 2018, Gisselquist Technology, LLC
//
// This design implements the parts and components found within Mahmoud's
// EETimes article, "Techniques to make clock switching glitch free."
// To the extent that this design is copied from that article, Gisselquist
// Technology asserts no copyright claims.
//
// However, the formal properties at the end of the design are owned and
// copyrighted by Gisselquist Technology, LLC.  They are hereby released as
// free software (firmware): you can redistribute them and/or modify them
// under the terms of  the GNU General Public License as published by the Free
// Software Foundation, either version 3 of the License, or (at your option)
// any later version.
//
// This program is distributed in the hope that it will be useful, but WITHOUT
// ANY WARRANTY; without even the implied warranty of MERCHANTIBILITY or
// FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
// for more details.
//
// License:	GPL, v3, as defined and found on www.gnu.org,
//		http://www.gnu.org/licenses/gpl.html
//
//
////////////////////////////////////////////////////////////////////////////////
//
//
`default_nettype	none
//
module clkswitch(i_clk_a, i_clk_b, i_areset_n, i_sel, o_clk);
	parameter [0:0]	OPT_COVER = 1'b0;
	input	wire	i_clk_a, i_clk_b;
	input	wire	i_areset_n;
	input	wire	i_sel;
	output	wire	o_clk;

	reg		aff, bff, a_sel, b_sel;

	// First half of the synchronizer for A
	//
	// Set aff on the positive edge of clock A
	//initial aff = 0;
	always @(posedge i_clk_a, negedge i_areset_n)
	if (!i_areset_n)
		aff <= 1;
	else
		aff <= (i_sel)&&(!b_sel);

	// Second half of the synchronizer for A
	//
	// Set a_sel based upon the negative edge of clock A
	//
	//initial a_sel = 0;
	always @(negedge i_clk_a, negedge i_areset_n)
	if (!i_areset_n)
		a_sel <= 1;
	else
		a_sel <= aff;


	// The logic for B's side is identical, save that it is based
	// upon the negation of our select signal.

	//initial bff = 0;
	always @(posedge i_clk_b, negedge i_areset_n)
	if (!i_areset_n)
		bff <= 0;
	else
		bff <= (!i_sel)&&(!a_sel);

	//initial b_sel = 0;
	always @(negedge i_clk_b, negedge i_areset_n)
	if (!i_areset_n)
		b_sel <= 0;
	else
		b_sel <= bff;

	assign	o_clk = ((a_sel)&&(i_clk_a))
			||((b_sel)&&(i_clk_b));

`ifdef	FORMAL
	reg	f_past_valid;
	initial	f_past_valid = 0;
	always @($global_clock)
		f_past_valid <= 1'b1;

	////////////////////////////////////////////////////////////////
	//
	// Reset properties
	//
	////////////////////////////////////////////////////////////////
	//
	//
	// Assume the design starts in the reset state
	initial	assume(!i_areset_n);

	always @($global_clock)
	if (!i_areset_n)
	begin
		assert((a_sel)&&(aff));
		assert((!b_sel)&&(!bff));
	end


	////////////////////////////////////////////////////////////////
	//
	// Formally generate (i.e. assume the existence of) two clocks
	// with an arbitrary phase relationship between them.
	//
	////////////////////////////////////////////////////////////////
	//
	wire	[7:0]	f_a_step, f_b_step;
	reg	[7:0]	f_last_transition;

	assign	f_a_step = $anyconst;
	assign	f_b_step = $anyconst;
	always @(*)
	begin
		assume((f_a_step > 8'h4)&&(f_a_step[7] == 1'b0));
		assume((f_b_step > 8'h4)&&(f_b_step[7] == 1'b0));
	end

	reg	[7:0]	f_a_state, f_b_state;

	initial	assume(f_a_state == 0);
	initial	assume(f_b_state == 0);
	always @($global_clock)
	begin
		if (!i_areset_n)
		begin
			f_a_state <= 0;
			f_b_state <= 0;
		end else begin
			f_a_state <= f_a_state + f_a_step;
			f_b_state <= f_b_state + f_b_step;
		end
	end

	always @(*)
	begin
		assume(i_clk_a == f_a_state[7]);
		assume(i_clk_b == f_b_state[7]);
	end

	////////////////////////////////////////////////////////////////
	//
	//  Criteria #1: The outgoing clock should only transition when one
	//  of the incoming clocks transitions
	//
	////////////////////////////////////////////////////////////////
	//
	//
	always @($global_clock)
	if ((f_past_valid)&&(i_areset_n)&&(!$rose(i_clk_a))&&(!$rose(i_clk_b)))
		assert(!$rose(o_clk));

	always @($global_clock)
	if ((f_past_valid)&&(i_areset_n)&&(!$fell(i_clk_a))&&(!$fell(i_clk_b)))
		assert(!$fell(o_clk));

	////////////////////////////////////////////////////////////////
	//
	// Criteria #2
	//
	////////////////////////////////////////////////////////////////
	//
	//
	always @($global_clock)
		assert((!a_sel)||(!b_sel));

	always @($global_clock)
	if ((f_past_valid)&&(i_areset_n)&&(o_clk != $past(o_clk)))
	begin
		if (o_clk)
		begin
			if (a_sel)
				assert((i_clk_a)&&(!$past(i_clk_a)));
			if (b_sel)
				assert((i_clk_b)&&(!$past(i_clk_b)));
		end else // if (!o_clk)
		begin
			if (a_sel)
				assert((!i_clk_a)&&($past(i_clk_a)));
			if (b_sel)
				assert((!i_clk_b)&&($past(i_clk_b)));
		end
	end

	////////////////////////////////////////////////////////////////
	//
	// Cover properties
	//
	// Prove that we can switch from one clock speed to another
	//
	////////////////////////////////////////////////////////////////
	//
	//
	// Start by counting the number of times each incoming clock
	// is responsible for ticking the outgoing clock
	//
	reg	[2:0]	a_ticks, last_a_ticks;

	initial	a_ticks = 0;
	always @($global_clock)
		if (!i_areset_n)
			a_ticks <= 0;
		else if ($rose(i_clk_a)&&(a_sel)&&(! &a_ticks))
			a_ticks <= a_ticks + 1'b1;
		else if (b_sel)
			a_ticks <= 0;

	initial	last_a_ticks = 0;
	always @($global_clock)
	if (!i_areset_n)
		last_a_ticks <= 0;
	else if ((f_past_valid)&&($past(a_sel)))
		last_a_ticks <= a_ticks;

	//
	// Repeat for clock B
	reg	[2:0]	b_ticks, last_b_ticks;
	initial	b_ticks = 0;
	always @($global_clock)
		if (!i_areset_n)
			b_ticks <= 0;
		else if ($rose(i_clk_b)&&(b_sel)&&(! &b_ticks))
			b_ticks <= b_ticks + 1'b1;
		else if (a_sel)
			b_ticks <= 0;

	initial	last_b_ticks = 0;
	always @($global_clock)
	if (!i_areset_n)
		last_b_ticks <= 0;
	else if ((f_past_valid)&&($past(b_sel)))
		last_b_ticks <= b_ticks;

	generate if (OPT_COVER)
	begin
		// Only one clock should ever be active at any time
		always @($global_clock)
		assert((a_ticks == 0)||(b_ticks == 0));

		always @($global_clock)
		if ((f_past_valid)&&($past(a_sel))&&(a_ticks == 0))
			assume(i_sel);

		always @($global_clock)
		if ((f_past_valid)&&($past(b_sel))&&(b_ticks == 0))
			assume(!i_sel);

		always @($global_clock)
		cover((f_past_valid)&&(&last_a_ticks)&&(&b_ticks)&&(b_sel)
			&&(f_a_step > (f_b_step<<1)));

		always @($global_clock)
		cover((f_past_valid)&&(&last_b_ticks)&&(&a_ticks)&&(a_sel)
			&&(f_a_step > (f_b_step<<1)));
	end endgenerate

	////////////////////////////////////////////////////////////////
	//
	// THE CRITICAL ASSUMPTION!
	//
	////////////////////////////////////////////////////////////////
	//
	//
	always @($global_clock)
	if ((a_sel != aff)||(b_sel != bff))
		assume($stable(i_sel));

	always @($global_clock)
	if ((f_past_valid)&&($past(i_sel))&&(!a_sel))
		assume(i_sel);

	always @($global_clock)
	if ((f_past_valid)&&(!$past(i_sel))&&(!b_sel))
		assume(!i_sel);


	////////////////////////////////////////////////////////////////
	//
	// Induction properties
	//
	////////////////////////////////////////////////////////////////
	//
	//

	always @(*)
	if (aff != a_sel)
		assert(bff == b_sel);

	always @(*)
	if (bff != b_sel)
		assert(aff == a_sel);

`endif
endmodule
