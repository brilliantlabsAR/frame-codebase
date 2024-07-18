import asyncio
from frameutils import Bluetooth


async def main():
    b = Bluetooth()

    await b.connect(print_response_handler=lambda s: print(s))

    # Print text in all the corners
    await b.send_lua("frame.display.text('Test', 1, 1)")
    await b.send_lua("frame.display.text('Test', 563, 1)")
    await b.send_lua("frame.display.text('Test', 1, 352)")
    await b.send_lua("frame.display.text('Test', 563, 352)")
    await b.send_lua("frame.display.show()")
    await asyncio.sleep(2.00)

    # Test UTF-8 characters
    await b.send_lua("frame.display.text('ÄÖÅ', 50, 50)")
    await b.send_lua("frame.display.show()")
    await asyncio.sleep(2.00)

    # Test spacing
    await b.send_lua("frame.display.text('Test', 50, 50, { spacing = 0})")
    await b.send_lua("frame.display.text('Test', 50, 100, { spacing = 2})")
    await b.send_lua("frame.display.text('Test', 50, 150, { spacing = 4})")
    await b.send_lua("frame.display.text('Test', 50, 200, { spacing = 10})")
    await b.send_lua("frame.display.text('Test', 50, 250, { spacing = 25})")
    await b.send_lua("frame.display.show()")
    await asyncio.sleep(2.00)

    # Print all colors
    await b.send_lua("frame.display.text('WHITE', 1, 1, { color = 'WHITE' })")
    await b.send_lua("frame.display.text('GREY', 1, 50, { color = 'GREY' })")
    await b.send_lua("frame.display.text('RED', 1, 100, { color = 'RED' })")
    await b.send_lua("frame.display.text('PINK', 1, 150, { color = 'PINK' })")
    await b.send_lua("frame.display.text('DARKBROWN', 1, 200, { color = 'DARKBROWN' })")
    await b.send_lua("frame.display.text('BROWN', 1, 250, { color = 'BROWN' })")
    await b.send_lua("frame.display.text('ORANGE', 1, 300, { color = 'ORANGE' })")
    await b.send_lua("frame.display.text('YELLOW', 1, 350, { color = 'YELLOW' })")
    await b.send_lua("frame.display.text('DARKGREEN', 320, 1, { color = 'DARKGREEN' })")
    await b.send_lua("frame.display.text('GREEN', 320, 50, { color = 'GREEN' })")
    await b.send_lua(
        "frame.display.text('LIGHTGREEN', 320, 100, { color = 'LIGHTGREEN' })"
    )
    await b.send_lua(
        "frame.display.text('NIGHTBLUE', 320, 150, { color = 'NIGHTBLUE' })"
    )
    await b.send_lua("frame.display.text('SEABLUE', 320, 200, { color = 'SEABLUE' })")
    await b.send_lua("frame.display.text('SKYBLUE', 320, 250, { color = 'SKYBLUE' })")
    await b.send_lua(
        "frame.display.text('CLOUDBLUE', 320, 300, { color = 'CLOUDBLUE' })"
    )
    await b.send_lua("frame.display.show()")
    await asyncio.sleep(2.00)

    # Change colors
    await b.send_lua("frame.display.assign_color_ycbcr('CLOUDBLUE', 15, 4, 4)")
    await b.send_lua("frame.display.assign_color_ycbcr('WHITE', 7, 4, 4)")
    await b.send_lua("frame.display.assign_color_ycbcr('GREY', 5, 3, 6)")
    await b.send_lua("frame.display.assign_color_ycbcr('RED', 9, 3, 5)")
    await b.send_lua("frame.display.assign_color_ycbcr('PINK', 2, 2, 5)")
    await b.send_lua("frame.display.assign_color_ycbcr('DARKBROWN', 4, 2, 5)")
    await b.send_lua("frame.display.assign_color_ycbcr('BROWN', 9, 2, 5)")
    await b.send_lua("frame.display.assign_color_ycbcr('ORANGE', 13, 2, 4)")
    await b.send_lua("frame.display.assign_color_ycbcr('YELLOW', 4, 4, 3)")
    await b.send_lua("frame.display.assign_color_ycbcr('DARKGREEN', 6, 2, 3)")
    await b.send_lua("frame.display.assign_color_ycbcr('GREEN', 10, 1, 3)")
    await b.send_lua("frame.display.assign_color_ycbcr('LIGHTGREEN', 1, 5, 2)")
    await b.send_lua("frame.display.assign_color_ycbcr('NIGHTBLUE', 4, 5, 2)")
    await b.send_lua("frame.display.assign_color_ycbcr('SEABLUE', 8, 5, 2)")
    await b.send_lua("frame.display.assign_color_ycbcr('SKYBLUE', 13, 4, 3)")
    await asyncio.sleep(5.00)

    # Change them back
    await b.send_lua("frame.display.assign_color_ycbcr('WHITE', 15, 4, 4)")
    await b.send_lua("frame.display.assign_color_ycbcr('GREY', 7, 4, 4)")
    await b.send_lua("frame.display.assign_color_ycbcr('RED', 5, 3, 6)")
    await b.send_lua("frame.display.assign_color_ycbcr('PINK', 9, 3, 5)")
    await b.send_lua("frame.display.assign_color_ycbcr('DARKBROWN', 2, 2, 5)")
    await b.send_lua("frame.display.assign_color_ycbcr('BROWN', 4, 2, 5)")
    await b.send_lua("frame.display.assign_color_ycbcr('ORANGE', 9, 2, 5)")
    await b.send_lua("frame.display.assign_color_ycbcr('YELLOW', 13, 2, 4)")
    await b.send_lua("frame.display.assign_color_ycbcr('DARKGREEN', 4, 4, 3)")
    await b.send_lua("frame.display.assign_color_ycbcr('GREEN', 6, 2, 3)")
    await b.send_lua("frame.display.assign_color_ycbcr('LIGHTGREEN', 10, 1, 3)")
    await b.send_lua("frame.display.assign_color_ycbcr('NIGHTBLUE', 1, 5, 2)")
    await b.send_lua("frame.display.assign_color_ycbcr('SEABLUE', 4, 5, 2)")
    await b.send_lua("frame.display.assign_color_ycbcr('SKYBLUE', 8, 5, 2)")
    await b.send_lua("frame.display.assign_color_ycbcr('CLOUDBLUE', 13, 4, 3)")

    await b.disconnect()


asyncio.run(main())
