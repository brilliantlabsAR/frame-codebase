`ifndef __JPEG_ENCODER_VH__ 
`define __JPEG_ENCODER_VH__

// USE DSP Slice
`define QUANTIZER_USE_DSP_MULT
`define DCT_USE_DSP_MULT
`define RGB2YUV_USE_DSP_MULT

// 4 possible QF
`ifndef QF0
`define QF0 50
`endif

`ifndef QF1
`define QF1 100
`endif

`ifndef QF2
`define QF2 10
`endif

`ifndef QF3
`define QF3 25
`endif

`endif // __JPEG_ENCODER_VH__
