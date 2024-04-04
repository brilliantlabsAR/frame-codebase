# Brilliant Frame FPGA

The Frame FPGA architecture consists of three major components. The SPI driver, the graphics pipeline and the camera pipeline.

## Architecture

![FPGA architecture block diagram for Frame](diagrams/fpga-architecture.drawio.png)

## SPI Driver

The SPI driver interfaces the FPGA with the nRF52. The FPGA is fully driven over SPI and provides access to the graphics and camera pipelines.

### Registers

Each function is accessed through a register. Registers are always addressed by one byte, followed by a various number of read or write bytes based on the operation.

| Address | Function                    | Description | 
|:-------:|-----------------------------|-------------|
| 0x10    | `GRAPHICS_CLEAR`            | Clears the background frame buffer.
| 0x11    | `GRAPHICS_ASSIGN_COLOR`     | Assigns a color to one of the 16 color palette slots. Color should be provided in YCbCr format.<br>**Write: `palette_index[7:0]`**<br>**Write: `y[7:0]`**<br>**Write: `cb[7:0]`**<br>**Write: `cr[7:0]`**
| 0x12    | `GRAPHICS_DRAW_SPRITE`      | Draws a sprite on the screen. The first two arguments specify an absolute x and y position to print the sprite. The sprite will be printed from its top left corner. The third argument determines the width of the sprite in pixels. The fourth argument determines the number of colors contained in the sprite. This value may be 2, 4, or 16. The final argument specifies the color palette offset for assigning the color values held in the sprite against the stored colors in the palette. Following bytes will then be printed on the background frame buffer.<br>**Write: `x_position[15:0]`**<br>**Write: `y_position[15:0]`**<br>**Write: `width[15:0]`**<br>**Write: `total_colors[7:0]`**<br>**Write: `palette_offset[7:0]`**<br>**Write: `pixel_data[7:0]`**<br>**...**<br>**Write: `pixel_data[7:0]`**<br>
| 0x13    | `GRAPHICS_DRAW_VECTOR`      | Draws a cubic Bézier curve from the start position to the end position. Control points 1 and 2 are relative to the start and end positions respectively, and are used to determine the shape of the curve. The final argument determines the color used from the current palette, and can be between 0 and 15.<br>**Write: `x_start_position[15:0]`**<br>**Write: `y_start_position[15:0]`**<br>**Write: `x_end_position[15:0]`**<br>**Write: `y_end_position[15:0]`**<br>**Write: `ctrl_1_x_position[15:0]`**<br>**Write: `ctrl_1_y_position[15:0]`**<br>**Write: `ctrl_2_x_position[15:0]`**<br>**Write: `ctrl_2_y_position[15:0]`**<br>**Write: `color[7:0]`**
| 0x14    | `GRAPHICS_BUFFER_SHOW`      | The foreground and background buffers are switched. The new foreground buffer is continuously rendered to the display, and the background buffer can be used to load new draw commands.
| 0x20    | `CAMERA_CAPTURE`            | Starts a new image capture.
| 0x21    | `CAMERA_BYTES_AVAILABLE`    | Returns how many bytes are available to read within the capture memory.<br>**Read: `bytes_available[23:0]`**
| 0x22    | `CAMERA_READ_BYTES`         | Reads a number of bytes from the capture memory.<br>**Read: `data[7:0]`**<br>**...**<br>**Read: `data[7:0]`**
| 0x23    | `CAMERA_ZOOM`               | Sets the zoom factor. A setting of `1` captures a 720x720 image, `2` captures 360x360, `3` captures 240x240, and `4` captures 180x180.<br>**Write: `zoom_factor[7:0]`**
| 0x24    | `CAMERA_PAN`                | Pans the capture window up or down in discrete steps. A setting of `10` captures the top-most part of the image, `0` is the middle, and `-10` is the bottom-most<br>**Write: `pan_position[7:0]`**
| 0x25    | `CAMERA_READ_METERING`      | Returns the current brightness levels for the red, green and blue channels of the camera. Two sets of values are returned representing spot and average metering.<br>**Read: `center_red_level[7:0]`**<br>**Read: `center_green_level[7:0]`**<br>**Read: `center_blue_level[7:0]`**<br>**Read: `average_red_level[7:0]`**<br>**Read: `average_green_level[7:0]`**<br>**Read: `average_blue_level[7:0]`**
| 0x26    | `CAMERA_COMPRESSION_FACTOR` | Sets the compression factor of the saved image between `-10` and `10`.<br>**Write: `compression_factor[7:0]`**
| 0xDB    | `GET_CHIP_ID`               | Returns the chip ID value.<br>**Read: `0x81`**

## Graphics

The graphics pipeline consists of 4 sub-components. The sprite engine, the vector engine, the frame buffers and the output driver.

Two types of graphics may be drawn. Sprites, such as text, or vectors such as lines or curves. Both types of graphics may be drawn on the screen at the same time.

![Graphics pipeline for Frame](diagrams/graphics-pipeline-architecture.drawio.png)

### 16 Color Palette

The display connected to Frame is a 640x400 color display. With a color depth of 4 bits per pixel (i.e. 16 colors), four of the five 512kb on chip RAM blocks can be used to create two frame buffers. While one frame buffer is being rendered onto the display, the other is used to assemble graphics. Once this buffer is ready, they are swapped.

Rather than limiting the graphics to 16 fixed colors, each color index is mapped to a user configurable 10bit YCbCr color value.

The color at index 0, is always expected to be the transparent (black) background color. This can be overridden if a transparent background isn't needed.

![Graphics color palette on Frame](diagrams/graphics-color-palette.drawio.png)

### Sprite Graphics

Bitmap sprites can be drawn using the `GRAPHICS_DRAW_SPRITE` command.

Sprites can be position anywhere on the screen and will render from the top left corner of the sprite origin. The `width` parameter determines how many pixels the sprite engine will print on a line before automatically returning to the first column, one row of pixels down.

Sprite data can be in one of three color formats. 1bit color, 2bit color and 4bit color. Each format allows for 2, 4 and 16 colors respectively, including the transparent (black) background color. The benefit of the lower color formats is that more pixels can be included per byte of transfer to the FPGA. This allows for faster rendering and a reduced storage requirement on the nRF52 main processor. 

When printing a single sprite, the `palette_offset` parameter can be provided to shift which colors are used. This allows for a 1bit font sprite to take on a different color from anywhere in the palette. This option can be changed on a sprite by sprite basis.

![Sprite graphics on Frame](diagrams/graphics-sprite-engine.drawio.png)

### Vector Graphics

Vectors can be drawn with the `GRAPHICS_DRAW_VECTOR` command. By setting the control points to 0, straight lines can also be drawn.

![Vector graphics on Frame](diagrams/graphics-vector-engine.drawio.png)

## Camera

The complete pipeline for the camera subsection is as follows:

![Camera pipeline for Frame](diagrams/camera-pipeline-architecture.drawio.png)

### Capturing Images

TODO

## Licence

Copyright © 2023 Brilliant Labs Limited

Licensed under CERN Open Hardware Licence Version 2 - Permissive
