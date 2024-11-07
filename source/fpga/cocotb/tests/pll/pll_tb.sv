
module pll_tb();

`include "dumper.vh"
GSR GSR_INST (.GSR_N('1), .CLK('0));

// Clocking
logic osc_clock;
logic camera_clock;
logic display_clock;
logic spi_peripheral_clock;
logic jpeg_buffer_clock;        // 2x JPEG clock for transpose/zig-zag buffer overclocking -  goes to JPEG
logic camera_pixel_clock;

logic pll_locked;
logic pll_reset;
logic pllpowerdown_n;
logic sim_ip_pll_locked;

OSCA #(
    .HF_CLK_DIV("24"),
    .HF_OSC_EN("ENABLED"),
    .LF_OUTPUT_EN("DISABLED")
    ) osc (
    .HFOUTEN(1'b1),
    .HFCLKOUT(osc_clock) // f = (450 / (HF_CLK_DIV + 1)) ± 7%
);


//always_comb pll_reset = 0;
//always_comb pllpowerdown_n = 1;

pll_wrapper pll_wrapper (
    .clki_i(osc_clock),                 // 18MHz
    .rstn_i(pll_reset),
    .pllpowerdown_n(pllpowerdown_n),
    .clkop_o(camera_clock),             // 24MHz
    .clkos_o(camera_pixel_clock),       // 36MHz
    .clkos2_o(display_clock),           // 36MHz
    .clkos3_o(spi_peripheral_clock),    // 72MHz - remove
    .clkos4_o(jpeg_buffer_clock),       // 78MHz - remove
    .lock_o(pll_locked)
);

pll_sim_ip pll_sim_ip (
    .clki_i(osc_clock),
    .clkop_o( ),
    .clkos_o( ),
    .clkos2_o( ),
    .clkos5_o( ),
    .lock_o(sim_ip_pll_locked)
);

endmodule
