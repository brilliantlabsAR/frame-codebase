# Brilliant Frame FPGA

FPGA architecture for Frame.

## Architecture

![FPGA architecture block diagram for Frame](docs/top-level-architecture.drawio.png)

## SPI Driver

### Registers

| Address | Function                        | Description | 
|:-------:|---------------------------------|-------------|
| 0x10    | GRAPHICS_ASSIGN_COLOR_PALLET    | Assigns a color to one of the 16 color palette slots. Color should be provided in YCbCr format.<br>**Write: <palette-index[7:0]>**<br>**Write: <y[7:0]>**<br>**Write: <cb[3:0]>**<br>**Write: <cr[3:0]>**
| 0x11    | GRAPHICS_MOVE_CURSOR            | Moves the drawing cursor to a specified absolute co-ordinate. Subsequent draws will start from this position and the cursor will move to the new end position after draw commands are processed.<br>**Write: <x-pos[15:0]>**<br>**Write: <y-pos[15:0]>**
| 0x12    | GRAPHICS_SET_PIXEL_DEPTH        | Selects between 1bpp, 2bpp, and 4bpp for printing pixels to the display. Color selection is therefore limited to 2, 4 and 16 colors respectively based on which mode is active.<br>**Write: <mode[7:0]>**
| 0x13    | GRAPHICS_SET_PIXEL_DRAW_WIDTH   | Sets how many pixels are drawn on a single line before the draw cursor moves to the next line.<br>**Write: <width[7:0]>**
| 0x13    | GRAPHICS_SET_PIXEL_COLOR_OFFSET | Offset allows 1bpp or 2bpp pixels to use a different subset of colors. Rather than being limited to the first 2 colors for example, an offset of 1 would cause pixels to use the second two colors of the pallet.<br>**Write: <width[7:0]>**
| 0x14    | GRAPHICS_DRAW_PIXELS            | Draws pixels on the screen. 2, 4 or 8 pixels may be drawn per byte based on the currently active PIXEL_DEPTH mode.<br>**Write: <pixel-data[7:0]>**<br>**Write: <pixel-data[7:0]>**<br>**...**
| 0x15    | GRAPHICS_SET_VECTOR_COLOR       | Sets the color for upcoming DRAW_VECTOR commands to one of the colors in the color palette.<br>**Write: <palette-index[7:0]>**
| 0x16    | GRAPHICS_DRAW_VECTOR_CURVE      | Draws a cubic Bezier curve from the current cursor position to the end position. Control points 1 and 2 are used to determine the shape of the curve.<br>**Write: <x-end[15:0]>**<br>**Write: <y-end[15:0]>**<br>**Write: <ctrl-1-x-position[15:0]>**<br>**Write: <ctrl-1-y-position[15:0]>**<br>**Write: <ctrl-2-x-position[15:0]>**<br>**Write: <ctrl-2-y-position[15:0]>**
| 0x17    | GRAPHICS_BUFFER_SHOW            | The foreground and background buffers are switched. The new foreground buffer is continuously rendered to the display, and the background buffer can be used to load new draw commands.
| 0x20    | CAMERA_CAPTURE                  | Starts a new image capture.
| 0x21    | CAMERA_BYTES_AVAILABLE          | Returns how many bytes are available in the capture memory. Returns -1 once all bytes have been read for the current capture, or no capture has been started<br>**Read: <bytes-available[23:0]**
| 0x22    | CAMERA_READ_BYTES               | Reads a number of bytes from the capture memory.<br>**Read: <data[...]>**
| 0xDB    | GET_CHIP_ID                     | Returns the chip ID value.<br>**Read: <0x81>**

## Graphics

### 16 Color Pallet

A maximum of 16 colors may be shown on the display at one time. Each color can itself be assigned to any real color.

For vector drawings, any of the colors may be selected. For pixel drawings, the colors may be limited to 2, 4 colors based on the pixel color depth, however the offset may used to select different subsets of colors.

![Graphics color pallet on Frame](docs/graphics-color-pallet.drawio.png)

### Pixel Printing

![Pixel printing on Frame](docs/graphics-pixel-printing.drawio.png)

### Vector Printing

![Vector printing on Frame](docs/graphics-vector-printing.drawio.png)

### Graphics Architecture

The complete pipeline for the graphics subsection is as follows:

![Graphics pipeline for Frame](docs/graphics-pipeline-architecture.drawio.png)

## Camera

### Capturing Images

TODO

### Camera Architecture

The complete pipeline for the camera subsection is as follows:

![Camera pipeline for Frame](docs/camera-pipeline-architecture.drawio.png)

## Licence

Copyright © 2023 Brilliant Labs Limited

Licensed under CERN Open Hardware Licence Version 2 - Permissive
