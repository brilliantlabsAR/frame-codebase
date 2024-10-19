////////////////////////////////////////////////////////////////////////////////
//
// Filename: 	afifo.v
//
// Project:	afifo, A formal proof of Cliff Cummings' asynchronous FIFO
//
// Purpose:	This file defines the behaviour of an asynchronous FIFO.
//		It was originally copied from a paper by Clifford E. Cummings
//	of Sunburst Design, Inc.  Since then, many of the variable names have
//	been changed and the logic has been rearranged.  However, the
//	fundamental logic remains the same.
//
// Creator:	Dan Gisselquist, Ph.D.
//		Gisselquist Technology, LLC
//
////////////////////////////////////////////////////////////////////////////////
//
//  Adopted by: Robert Metchev / Chips & Scripts (rmetchev@ieee.org)
//  for Brilliant Labs Ltd.
//
////////////////////////////////////////////////////////////////////////////////
//
// The Verilog logic for this project comes from the paper by Clifford E.
// Cummings, of Sunburst Design, Inc, titled: "Simulation and Synthesis
// Techniques for Asynchronous FIFO Design".  This paper may be found at
// sunburst-design.com.
//
// Minor edits to that logic have been made by Gisselquist Technology, LLC.
// Gisselquist Technology, LLC, asserts no copywrite or ownership of these
// minor edits.
//
//
//
// The formal properties within this project, contained between the
// `ifdef FORMAL line and its corresponding `endif, are owned by Gisselquist
// Technology, LLC, and Copyrighted as such.  Hence, the following copyright
// statement regarding these properties:
//
// Copyright (C) 2018, Gisselquist Technology, LLC
//
// These properties are free software (firmware): you can redistribute it and/or
// modify it under the terms of  the GNU General Public License as published
// by the Free Software Foundation, either version 3 of the License, or (at
// your option) any later version.
//
// This program is distributed in the hope that it will be useful, but WITHOUT
// ANY WARRANTY; without even the implied warranty of MERCHANTIBILITY or
// FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
// for more details.
//
// You should have received a copy of the GNU General Public License along
// with this program.  (It's in the $(ROOT)/doc directory.  Run make with no
// target there if the PDF file isn't present.)  If not, see
// <http://www.gnu.org/licenses/> for a copy.
//
// License:	GPL, v3, as defined and found on www.gnu.org,
//		http://www.gnu.org/licenses/gpl.html
//
//
////////////////////////////////////////////////////////////////////////////////
//
//

//`default_nettype	none
//
//
module afifo(i_wclk, i_wrst_n, i_wr, i_wdata, o_wfull,
		i_rclk, i_rrst_n, i_rd, o_rdata, o_rempty, wptr, rptr);
	parameter	DSIZE = 2,
			ASIZE = 4, FULL_EMPTY_SAFEGUARD = 1;
	localparam	DW = DSIZE,
			AW = ASIZE;
	input	wire			i_wclk, i_wrst_n, i_wr;
	input	wire	[DW-1:0]	i_wdata;
	output	reg			o_wfull;
	input	wire			i_rclk, i_rrst_n, i_rd;
	output	wire	[DW-1:0]	o_rdata;
	output	reg			o_rempty;
	output	wire    [AW:0]          wptr, rptr;

	wire	[AW-1:0]	waddr, raddr;
	wire			wfull_next, rempty_next;
	reg	[AW:0]		wgray, wbin, wq2_rgray, wq1_rgray,
				rgray, rbin, rq2_wgray, rq1_wgray;
	//
	wire	[AW:0]		wgraynext, wbinnext;
	wire	[AW:0]		rgraynext, rbinnext;

	reg	[DW-1:0]	mem	[0:((1<<AW)-1)];

	/////////////////////////////////////////////
	//
	//
	// Write logic
	//
	//
	/////////////////////////////////////////////

	//
	// Cross clock domains
	//
	// Cross the read Gray pointer into the write clock domain
	initial	{ wq2_rgray,  wq1_rgray } = 0;
	always @(posedge i_wclk ) // or negedge i_wrst_n)
	if (!i_wrst_n)
		{ wq2_rgray, wq1_rgray } <= 0;
	else
		{ wq2_rgray, wq1_rgray } <= { wq1_rgray, rgray };



	// Calculate the next write address, and the next graycode pointer.
	assign	wbinnext  = wbin + { {(AW){1'b0}}, ((i_wr) && (!o_wfull || !FULL_EMPTY_SAFEGUARD)) };
	assign	wgraynext = (wbinnext >> 1) ^ wbinnext;

	assign	waddr = wbin[AW-1:0];
	assign	wptr = wbin;

	// Register these two values--the address and its Gray code
	// representation
	initial	{ wbin, wgray } = 0;
	always @(posedge i_wclk ) // or negedge i_wrst_n)
	if (!i_wrst_n)
		{ wbin, wgray } <= 0;
	else
		{ wbin, wgray } <= { wbinnext, wgraynext };

	//assign	wfull_next = (wgraynext == { ~wq2_rgray[AW:AW-1],
	//assign	wfull_next = (wgray == { ~wq2_rgray[AW:AW-1],
	//			wq2_rgray[AW-2:0] });
	assign	wfull_next = (wgray == (wq2_rgray ^ (2'b11 << (AW-1))) );

	//
	// Calculate whether or not the register will be full on the next
	// clock.
	always_comb	o_wfull = wfull_next;
	//initial	o_wfull = wfull_next;
	//always @(posedge i_wclk ) // or negedge i_wrst_n)
	//if (!i_wrst_n)
	//	o_wfull <= 1'b0;
	//else
	//	o_wfull <= wfull_next;

	//
	// Write to the FIFO on a clock
	always @(posedge i_wclk)
	if ((i_wr)&&(!o_wfull || !FULL_EMPTY_SAFEGUARD))
		mem[waddr] <= i_wdata;

	////////////////////////////////////////////////////////////////////////
	////////////////////////////////////////////////////////////////////////
	//
	//
	// Read logic
	//
	//
	////////////////////////////////////////////////////////////////////////
	////////////////////////////////////////////////////////////////////////
	//
	//

	//
	// Cross clock domains
	//
	// Cross the write Gray pointer into the read clock domain
	initial	{ rq2_wgray,  rq1_wgray } = 0;
	always @(posedge i_rclk ) // or negedge i_rrst_n)
	if (!i_rrst_n)
		{ rq2_wgray, rq1_wgray } <= 0;
	else
		{ rq2_wgray, rq1_wgray } <= { rq1_wgray, wgray };


	// Calculate the next read address,
	assign	rbinnext  = rbin + { {(AW){1'b0}}, ((i_rd)&&(!o_rempty || !FULL_EMPTY_SAFEGUARD)) };
	// and the next Gray code version associated with it
	assign	rgraynext = (rbinnext >> 1) ^ rbinnext;

	// Register these two values, the read address and the Gray code version
	// of it, on the next read clock
	//
	initial	{ rbin, rgray } = 0;
	always @(posedge i_rclk ) // or negedge i_rrst_n)
	if (!i_rrst_n)
		{ rbin, rgray } <= 0;
	else
		{ rbin, rgray } <= { rbinnext, rgraynext };

	// Memory read address Gray code and pointer calculation
	assign	raddr = rbin[AW-1:0];
	assign	rptr = rbin;

	// Determine if we'll be empty on the next clock
	//assign	rempty_next = (rgraynext == rq2_wgray);
	assign	rempty_next = (rgray == rq2_wgray);

	always_comb o_rempty = rempty_next;
	//initial o_rempty = 1;
	//always @(posedge i_rclk ) // or negedge i_rrst_n)
	//if (!i_rrst_n)
	//	o_rempty <= 1'b1;
	//else
	//	o_rempty <= rempty_next;

	//
	// Read from the memory--a clockless read here, clocked by the next
	// read FLOP in the next processing stage (somewhere else)
	//
	assign	o_rdata = mem[raddr];


	////////////////////////////////////////////////////////////////////////
	////////////////////////////////////////////////////////////////////////
	//
	//  Formal properties
	//
	////////////////////////////////////////////////////////////////////////
	////////////////////////////////////////////////////////////////////////
	//
	//
`ifdef	FORMAL
`ifdef	AFIFO
`define	ASSUME	assume
`define	ASSERT	assert
`else
`define	ASSUME	assert
`define	ASSERT	assume
`endif
	//
	// Set up the f_past_valid registers.  We'll need one for each of
	// the three clock domains: write, read, and the global simulation
	// clock.
	//
	reg	f_past_valid_rd, f_past_valid_wr, f_past_valid_gbl;

	initial	f_past_valid_gbl = 0;
	always @($global_clock)
		f_past_valid_gbl <= 1'b1;

	initial	f_past_valid_wr  = 0;
	always @(posedge i_wclk)
		f_past_valid_wr  <= 1'b1;

	initial	f_past_valid_rd  = 0;
	always @(posedge i_rclk)
		f_past_valid_rd  <= 1'b1;

	always @(*)
	if (!f_past_valid_gbl)
		`ASSERT((!f_past_valid_wr)&&(!f_past_valid_rd));

	////////////////////////////////////////////////////////////////////////
	//
	// Setup the two clocks themselves.  We'll assert nothing regarding
	// their relative phases or speeds.
	//
	////////////////////////////////////////////////////////////////////////
	//
	//
`ifdef	AFIFO
	localparam	F_CLKBITS=5;
	wire	[F_CLKBITS-1:0]	f_wclk_step, f_rclk_step;

	assign	f_wclk_step = $anyconst;
	assign	f_rclk_step = $anyconst;
	always @(*)
		assume(f_wclk_step != 0);
	always @(*)
		assume(f_rclk_step != 0);

	reg	[F_CLKBITS-1:0]	f_wclk_count, f_rclk_count;

	always @($global_clock)
		f_wclk_count <= f_wclk_count + f_wclk_step;
	always @($global_clock)
		f_rclk_count <= f_rclk_count + f_rclk_step;

	always @(*)
	begin
		assume(i_wclk == f_wclk_count[F_CLKBITS-1]);
		assume(i_rclk == f_rclk_count[F_CLKBITS-1]);
	end
`endif

	////////////////////////////////////////////////////////////////////////
	//
	// Assumptions regarding the two reset inputs.  We'll insist that
	// the reset inputs follow some external reset logic, and that both
	// may be asynchronously asserted from that external reset wire, and
	// only ever synchronously de-asserted.
	//
	////////////////////////////////////////////////////////////////////////
	//
	//
	// initial	assume(!i_wrst_n);
	// initial	assume(!i_rrst_n);
	initial	assume(i_rrst_n == i_wrst_n);

	always @($global_clock)
		assume($fell(i_wrst_n)==$fell(i_rrst_n));

	always @($global_clock)
	if (!$rose(i_wclk))
		assume(!$rose(i_wrst_n));

	always @($global_clock)
	if (!$rose(i_rclk))
		assume(!$rose(i_rrst_n));

	always @($global_clock)
	if (!i_wrst_n)
		assert(rbin == 0);


	////////////////////////////////////////////////////
	//
	// Now let's make some assumptions about how our inputs can only ever
	// change on a clock edge.
	//
	////////////////////////////////////////////////////
	//
	//
	always @($global_clock)
	if (f_past_valid_gbl)
	begin
		if (!$rose(i_wclk))
		begin
			assume($stable(i_wr));
			assume($stable(i_wdata));
			assert($stable(o_wfull)||(!i_wrst_n));
		end

		if (!$rose(i_rclk))
		begin
			assume($stable(i_rd));
			assert((o_rempty)||($stable(o_rdata)));
			assert((!i_rrst_n)||($stable(o_rempty)));
		end
	end


	////////////////////////////////////////////////////
	//
	// Following any reset, several values must be in a known
	// configuration--including cross clock values.  assert
	// those here to insure a consistent state, to include the
	// states of their cross-clock domain counterparts.
	//
	////////////////////////////////////////////////////
	//
	//
	always @($global_clock)
	if ((!f_past_valid_wr)||(!i_wrst_n))
	begin
		`ASSUME(i_wr == 0);
		//
		`ASSERT(wgray == 0);
		`ASSERT(wbin == 0);
		`ASSERT(!o_wfull);
		//
		`ASSERT(wq1_rgray == 0);
		`ASSERT(wq2_rgray == 0);
		`ASSERT(rq1_wgray == 0);
		`ASSERT(rq2_wgray == 0);
		//
		`ASSERT(rbin == 0);
		`ASSERT(o_rempty);
	end

	always @($global_clock)
	if ((!f_past_valid_rd)||(!i_rrst_n))
	begin
		`ASSUME(i_rd == 0);
		//
		`ASSERT(rgray == 0);
		`ASSERT(rbin == 0);
		`ASSERT(rq1_wgray == 0);
		`ASSERT(rq2_wgray == 0);
		`ASSERT(wq1_rgray == 0);
		`ASSERT(wq2_rgray == 0);
	end

	////////////////////////////////////////////////////////////////////////
	//
	// Calculate the fill level of the FIFO.
	//
	////////////////////////////////////////////////////////////////////////
	//
	//
	// First, let's examine the asynchronous fill.  This is the "true"
	// fill of the FIFO that's never really known in either clock domain,
	// but we can fake it here in our "formal" environment.
	wire	[AW:0]		f_fill;

	assign	f_fill = (wbin - rbin);

	initial	`ASSERT(f_fill == 0);
	always @($global_clock)
		`ASSERT(f_fill <= { 1'b1, {(AW){1'b0}} });

	// Any time the FIFO is full, o_wfull should be true.  It may take a
	// clock or two to clear, though, so this is an implication and not
	// an equals.
	always @($global_clock)
	if (f_fill == {1'b1,{(AW){1'b0}}})
		`ASSERT(o_wfull);

	// If the FIFO is about to be full, the logic should be able
	// to detect that condition.
	always @($global_clock)
	if (f_fill == {1'b0,{(AW){1'b1}}})
		`ASSERT((wfull_next)||(!i_wr)||(o_wfull));

	// Any time the FIFO is empty, o_rempty should be true.  It may be
	// asserted true at other times as well (i.e. there's a lag before
	// its cleared), so this is an implication and not an equals.
	always @($global_clock)
	if (f_fill == 0)
		`ASSERT(o_rempty);

	// If the FIFO is about to be empty, the logic should be able
	// to detect that condition as well.
	always @($global_clock)
	if (f_fill == 1)
		`ASSERT((rempty_next)||(!i_rd)||(o_rempty));

	// The "wgray" variable should be a gray-coded copy of the binary
	// address wbin.
	always @(*)
		`ASSERT(wgray == ((wbin>>1)^wbin));
	// Same for rgray, the read gray register
	always @(*)
		`ASSERT(rgray == ((rbin>>1)^rbin));

	// The indication that the FIFO is full is that wgray and rgray are
	// equal--save that the top two bits of wgray need to be flipped for
	// this comparison.  See the paper for the details of this operation,
	// and why flipping these bits is necessary.
	always @(*)
		`ASSERT( (rgray == { ~wgray[AW:AW-1], wgray[AW-2:0] })
			== (f_fill == { 1'b1, {(AW){1'b0}} }) );

	// The gray pointers should only ever equal if the FIFO is empty,
	// hence the fill should be zero
	always @(*)
		`ASSERT((rgray == wgray) == (f_fill == 0));

	///////////////////////////////////////////////////////////////////////
	//
	// Now repeat, but this time from the reader or writers perspective
	//
	///////////////////////////////////////////////////////////////////////
	//
	//
	reg	[AW:0]	f_w2r_rbin, f_w1r_rbin,
			f_r2w_wbin, f_r1w_wbin;
	wire	[AW:0]	f_w2r_fill, f_r2w_fill;

	// Cross the binary value across clock domains.  Since this is formal,
	// and not real hardware, there's no metastability concerns requiring
	// grayscale.  Hence we can cross the full binary (address count) value
	initial	{ f_w2r_rbin, f_w1r_rbin } = 0;
	always @(posedge i_wclk or negedge i_wrst_n)
	if (!i_wrst_n)
		{ f_w2r_rbin, f_w1r_rbin } <= 0;
	else
		{ f_w2r_rbin, f_w1r_rbin } <= { f_w1r_rbin, rbin };

	initial	{ f_r2w_wbin, f_r1w_wbin } = 0;
	always @(posedge i_rclk or negedge i_rrst_n)
	if (!i_rrst_n)
		{ f_r2w_wbin, f_r1w_wbin } <= 0;
	else
		{ f_r2w_wbin, f_r1w_wbin } <= { f_r1w_wbin, wbin };

	//
	// Now calculate the fill from the perspective of each of the two
	// clock domains

	always @(*)
		`ASSERT(rq1_wgray == ((f_r1w_wbin>>1)^f_r1w_wbin));
	always @(*)
		`ASSERT(rq2_wgray == ((f_r2w_wbin>>1)^f_r2w_wbin));

	always @(*)
		`ASSERT(wq1_rgray == ((f_w1r_rbin>>1)^f_w1r_rbin));
	always @(*)
		`ASSERT(wq2_rgray == ((f_w2r_rbin>>1)^f_w2r_rbin));

	assign	f_w2r_fill = wbin - f_w2r_rbin;
	assign	f_r2w_fill = f_r2w_wbin - rbin;

	// And assert that the fill is always less than or equal to full.
	// This catches underrun as well as overflow, since underrun will
	// look like the fill suddenly increases
	always @(*)
		`ASSERT(f_w2r_fill <= { 1'b1, {(AW){1'b0}} });
	always @(*)
		`ASSERT(f_r2w_fill <= { 1'b1, {(AW){1'b0}} });

	// From the writers perspective, anytime the Gray pointers are
	// equal save for the top bit, the FIFO is full and should be asserted
	// as such.  It is possible for the FIFO to be asserted as full at
	// some other times as well.
	always @(*)
	if (wgray == { ~wq2_rgray[AW:AW-1], wq2_rgray[AW-2:0] })
		`ASSERT(o_wfull);

	// The same basic principle applies to the reader as well.  From the
	// readers perspective, anytime the Gray pointers are equal the FIFO
	// is empty, and should be asserted as such.
	always @(*)
	if (rgray == rq2_wgray)
		`ASSERT(o_rempty);

	////////////////////////////////////////////////////////////////////////
	//
	// One of the keys properties of this algorithm is that
	// no more than one bit of the gray coded values will ever
	// change from one clock and clock domain to the next.
	// Since this is a fundamental property of this algorithm,
	// let's make certain the algorithm is operating as we think
	// it should.
	//
	////////////////////////////////////////////////////////////////////////
	//
	//
`ifdef	ONEHOT
	always @(*)
		`ASSERT((wgray == wgray_next)
			||($onehot(wgray ^ wgray_next)));
	always @(*)
		`ASSERT((rq2_wgray == rq1_wgray)
			||($onehot(rq2_wgray ^ rq1_wgray)));
`else
	genvar	k;
	generate for(k=0; k<= AW; k=k+1)
	begin : CHECK_ONEHOT_WGRAY
		always @(*)
			`ASSERT((wgray[k] == wgraynext[k])
				||(wgray ^ wgraynext ^ (1<<k) == 0));
		always @(*)
			`ASSERT((rq2_wgray[k] == rq1_wgray[k])
				||(rq2_wgray ^ rq1_wgray ^ (1<<k) == 0));
	end endgenerate
`endif

`ifdef ONEHOT
	always @(*)
		`ASSERT((rgray == rgray_next)
			||($onehot(rgray ^ rgray_next)));
	always @(*)
		`ASSERT((wq2_rgray == wq1_rgray)
			||($onehot(wq2_rgray ^ wq1_rgray)));
`else
	genvar	k;
	generate for(k=0; k<= AW; k=k+1)
	begin : CHECK_ONEHOT_RGRAY
		always @(*)
			`ASSERT((rgray[k] == rgraynext[k])
				||(rgray ^ rgraynext ^ (1<<k) == 0));
		always @(*)
			`ASSERT((wq2_rgray[k] == wq1_rgray[k])
				||(wq2_rgray ^ wq1_rgray ^ (1<<k) == 0));
	end endgenerate
`endif

	////////////////////////////////////////////////////////////////////////
	//
	// THE FIFO CONTRACT
	//   Given any two subsequent values written, those same two values
	//   must be read out some time later in the same order
	//
	////////////////////////////////////////////////////////////////////////
	//
	//
`ifdef	AFIFO
	(* anyconst *) wire [AW:0]		f_const_addr;

	wire	[AW:0]		f_const_next_addr;
	assign	f_const_next_addr = f_const_addr + 1;

	(* anyconst *) reg [DW-1:0]	f_const_first, f_const_next;


	reg			f_addr_valid, f_next_valid;

	always @(*)
	begin
		f_addr_valid = 1'b0;
		if((wbin > rbin)&&(wbin > f_const_addr)
					&&(rbin <= f_const_addr))
			// Order rbin <= addr < wbin
			f_addr_valid = 1'b1;
		else if ((wbin < rbin)&&(f_const_addr < wbin))
			// addr < wbin < rbin
			f_addr_valid = 1'b1;
		else if ((wbin < rbin)&&(rbin <= f_const_addr))
			// wbin < rbin < addr
			f_addr_valid = 1'b1;
	end

	always @(*)
	begin
		f_next_valid = 1'b0;
		if((wbin > rbin)&&(wbin > f_const_next_addr)
					&&(rbin <= f_const_next_addr))
			// rbin <= addr < wbin
			f_next_valid = 1'b1;
		else if ((wbin < rbin)&&(f_const_next_addr < wbin))
			// addr < wbin < rbin
			f_next_valid = 1'b1;
		else if ((wbin < rbin)&&(rbin <= f_const_next_addr))
			// wbin < rbin < addr
			f_next_valid = 1'b1;
	end

	reg	f_first_in_fifo, f_second_in_fifo, f_both_in_fifo;

	always @(*)
		f_first_in_fifo = (f_addr_valid)
				&&(mem[f_const_addr[AW-1:0]]==f_const_first);
	always @(*)
		f_second_in_fifo = (f_next_valid)
				&&(mem[f_const_next_addr[AW-1:0]]==f_const_next);

	always @(*)
		f_both_in_fifo = (f_first_in_fifo)&&(f_second_in_fifo);

	reg	f_wait_for_first_read, f_read_first, f_read_second,
		f_wait_for_second_read;

	// States of interest
	always @(*)
		f_wait_for_first_read = (f_both_in_fifo)
				&&((!i_rd)||(f_const_addr != rbin)||(o_rempty));

	always @(*)
		f_read_first = (i_rd)&&(o_rdata == f_const_first)&&(!o_rempty)
			&&(rbin == f_const_addr)&&(f_both_in_fifo);

	always @(*)
		f_wait_for_second_read = (f_second_in_fifo)
				&&((!i_rd)||(o_rempty))
				&&(f_const_next_addr == rbin);

	always @(*)
		f_read_second = (i_rd)&&(o_rdata == f_const_next)&&(!o_rempty)
				&&(rbin == f_const_next_addr)
				&&(f_second_in_fifo);

	always @($global_clock)
	if ((f_past_valid_gbl)&&(i_wrst_n))
	begin
		if ((!$past(f_read_first))&&(($past(f_both_in_fifo))))
			assert((f_wait_for_first_read)
				|| (($rose(i_rclk))&&(f_read_first)));
		if ($past(f_read_first))
			assert(
				((!$rose(i_rclk))&&(f_read_first))
				||($rose(i_rclk)&&((f_read_second)
						||(f_wait_for_second_read))));
		if ($past(f_wait_for_second_read))
			assert((f_wait_for_second_read)
				||(($rose(i_rclk))&&(f_read_second)));
	end
`endif

	////////////////////////////////////////////////////
	//
	// Some cover statements, to make sure valuable states
	// are even reachable
	//
	////////////////////////////////////////////////////
	//

	// Make sure a reset is possible in either domain
	always @(posedge i_wclk)
		cover(i_wrst_n);

	always @(posedge i_rclk)
		cover(i_rrst_n);

	always @($global_clock)
	if (f_past_valid_gbl)
		cover((o_rempty)&&(!$past(o_rempty)));

	always @(*)
	if (f_past_valid_gbl)
		cover(o_wfull);

	always @(posedge i_wclk)
	if (f_past_valid_wr)
		cover($past(o_wfull)&&($past(i_wr))&&(o_wfull));

	always @(posedge i_wclk)
	if (f_past_valid_wr)
		cover($past(o_wfull)&&(!o_wfull));

	always @(posedge i_wclk)
		cover((o_wfull)&&(i_wr));

	always @(posedge i_wclk)
		cover(i_wr);

	always @(posedge i_rclk)
		cover((o_rempty)&&(i_rd));

`endif
endmodule
