# Brilliant Frame FPGA

The Frame FPGA architecture consists of three major components. The SPI driver, the graphics pipeline and the camera pipeline.

## Architecture

![FPGA architecture block diagram for Frame](docs/top-level-architecture.drawio.png)

## SPI Driver

The SPI driver interfaces the FPGA with the nRF52. The FPGA is fully driven over SPI and provides access to the graphics and camera pipelines.

### Registers

Each function is accessed through a register. Registers are always addressed by one byte, followed by a various number of read or write bytes based on the operation.

| Address | Function                        | Description | 
|:-------:|---------------------------------|-------------|
| 0x10    | GRAPHICS_ASSIGN_COLOR_PALLET    | Assigns a color to one of the 16 color palette slots. Color should be provided in YCbCr format.<br>**Write: <palette-index[7:0]>**<br>**Write: <y[7:0]>**<br>**Write: <cb[7:0]>**<br>**Write: <cr[7:0]>**
| 0x11    | GRAPHICS_MOVE_CURSOR            | Moves the drawing cursor to a specified absolute co-ordinate. Subsequent draws will start from this position and the cursor will move to the new end position after draw commands are processed.<br>**Write: <x-pos[15:0]>**<br>**Write: <y-pos[15:0]>**
| 0x12    | GRAPHICS_SET_PIXEL_COLORS       | Selects between 1, 2, 4 or 16 colors for printing pixels to the display. In the case of 1 color, a bit value of 0 represents the color stored in index 0 of the pallet.<br>**Write: <mode[7:0]>**
| 0x13    | GRAPHICS_SET_PIXEL_DRAW_WIDTH   | Sets how many pixels are drawn on a single line before the draw cursor moves to the next line.<br>**Write: <width[7:0]>**
| 0x13    | GRAPHICS_SET_PIXEL_COLOR_OFFSET | Offset allows the 1, 2 or 4 color modes to use a different subset of colors from the pallet. Unlike changing the pallet, this allows 2bpp or 4bpp images to take on different colors at the same time while still keeping SPI overhead low.<br>**Write: <offset[7:0]>**
| 0x14    | GRAPHICS_DRAW_PIXELS            | Draws pixels on the screen. 2, 4 or 8 pixels may be drawn per byte based on the currently active PIXEL_COLORS mode.<br>**Write: <pixel-data[7:0]>**<br>**Write: <pixel-data[7:0]>**<br>**...**
| 0x15    | GRAPHICS_SET_VECTOR_COLOR       | Sets the color for upcoming DRAW_VECTOR_CURVE commands to one of the colors stored in the color palette.<br>**Write: <palette-index[7:0]>**
| 0x16    | GRAPHICS_DRAW_VECTOR_CURVE      | Draws a cubic Bézier curve from the current cursor position to the end position. Control points 1 and 2 are relative to the cursor start and end positions, and are used to determine the shape of the curve.<br>**Write: <x-end[15:0]>**<br>**Write: <y-end[15:0]>**<br>**Write: <ctrl-1-x-position[15:0]>**<br>**Write: <ctrl-1-y-position[15:0]>**<br>**Write: <ctrl-2-x-position[15:0]>**<br>**Write: <ctrl-2-y-position[15:0]>**
| 0x17    | GRAPHICS_BUFFER_SHOW            | The foreground and background buffers are switched. The new foreground buffer is continuously rendered to the display, and the background buffer can be used to load new draw commands.
| 0x20    | CAMERA_CAPTURE                  | Starts a new image capture.
| 0x21    | CAMERA_BYTES_AVAILABLE          | Returns how many bytes are available in the capture memory. Returns -1 once all bytes have been read for the current capture, or no capture has been started<br>**Read: <bytes-available[23:0]**
| 0x22    | CAMERA_READ_BYTES               | Reads a number of bytes from the capture memory.<br>**Read: <data[...]>**
| 0xDB    | GET_CHIP_ID                     | Returns the chip ID value.<br>**Read: <0x81>**

## Graphics

The graphics pipeline consists of 4 sub-components. The sprite engine, the vector engine, the frame buffers and the output driver.

Two types of graphics may be drawn. Sprites, such as text, or vectors such as lines or curves. Both types of graphics may be drawn on the screen at the same time.

![Graphics pipeline for Frame](docs/graphics-pipeline-architecture.drawio.png)

### 16 Color Pallet

The display connected to Frame is a 640x400 color display. With a color depth of 4 bits per pixel (i.e. 16 colors), four of the five 512kb on chip RAM blocks can be used to create two frame buffers. While one frame buffer is being rendered onto the display, the other is used to assemble graphics. Once this buffer is ready, they are swapped.

Rather than limiting the graphics to 16 fixed colors, each color index is mapped to a user configurable 10bit YCbCr color value.

For vectors, any of the 16 colors may be selected, however For sprites, the colors may be limited to 1, 2 or 4 colors based on the currently set pixel color mode. A pallet offset can however be used to shift which group of colors are used per drawing. This allows for multiple color fonts for example.

![Graphics color pallet on Frame](docs/graphics-color-pallet.drawio.png)

### Pixel Printing

TODO

![Pixel printing on Frame](docs/graphics-pixel-printing.drawio.png)

### Vector Printing

Vectors can be drawn with the DRAW_CURVE command. By setting the control points to 0, straight lines can also be drawn.

![Vector printing on Frame](docs/graphics-vector-printing.drawio.png)

## Camera

The complete pipeline for the camera subsection is as follows:

![Camera pipeline for Frame](docs/camera-pipeline-architecture.drawio.png)

### Capturing Images

TODO

## Licence

Copyright © 2023 Brilliant Labs Limited

Licensed under CERN Open Hardware Licence Version 2 - Permissive
