from aioconsole import ainput
from frameutils import Bluetooth
import asyncio
import time


async def main():

    main_script = """
    require("graphics")
    
    local graphics = Graphics.new()
    local last_print_time = 0

    graphics:append_text("This is a test. The quick brown fox jumps over the lazy dog.", "\\u{F0000}")
    
    while true do
        if frame.time.utc() - last_print_time > 0.07 then
            graphics:print()
            last_print_time = frame.time.utc()
        end
        
        collectgarbage("collect")
    end
    """

    graphics_script = r"""
    Graphics = {}
    Graphics.__index = Graphics

    function Graphics.new()
        local self = setmetatable({}, Graphics)
        self:clear()
        return self
    end

    function Graphics:clear()
        -- Set by append_text function
        self.__text = ""
        self.__emoji = ""
        -- Used internally by print function
        self.__this_line = ""
        self.__last_line = ""
        self.__last_last_line = ""
        self.__starting_index = 1
        self.__current_index = 1
        self.__ending_index = 1
        self.__done_function = (function() end)()
    end

    function Graphics:append_text(data, emoji)
        self.__text = self.__text .. string.gsub(data, '\\n+', ' ')
        self.__emoji = emoji
    end

    function Graphics:on_complete(func)
        self.__done_function = func
    end

    function Graphics.__print_layout(last_last_line, last_line, this_line, emoji)
        local TOP_MARGIN = 118
        local LINE_SPACING = 58
        local EMOJI_MAX_WIDTH = 91

        frame.display.text(emoji, 640 - EMOJI_MAX_WIDTH, TOP_MARGIN, { color = 'YELLOW' })

        if last_last_line == '' and last_line == '' then
            frame.display.text(this_line, 1, TOP_MARGIN)
        elseif last_last_line == '' then
            frame.display.text(last_line, 1, TOP_MARGIN)
            frame.display.text(this_line, 1, TOP_MARGIN + LINE_SPACING)
        else
            frame.display.text(last_last_line, 1, TOP_MARGIN)
            frame.display.text(last_line, 1, TOP_MARGIN + LINE_SPACING)
            frame.display.text(this_line, 1, TOP_MARGIN + LINE_SPACING * 2)
        end

        frame.display.show()
    end

    function Graphics:print()
        if self.__text:sub(self.__starting_index, self.__starting_index) == ' ' then
            self.__starting_index = self.__starting_index + 1
        end

        if self.__current_index >= self.__ending_index then
            self.__starting_index = self.__ending_index
            self.__last_last_line = self.__last_line
            self.__last_line = self.__this_line
            self.__starting_index = self.__ending_index
        end

        for i = self.__starting_index + 22, self.__starting_index, -1 do
            if self.__text:sub(i, i) == ' ' or self.__text:sub(i, i) == '' then
                self.__ending_index = i
                break
            end
        end

        self.__this_line = self.__text:sub(self.__starting_index, self.__current_index)

        self.__print_layout(self.__last_last_line, self.__last_line, self.__this_line, self.__emoji)

        if self.__current_index >= #self.__text then
            pcall(self.__done_function)
            self.__done_function = (function() end)()
            return
        end

        self.__current_index = self.__current_index + 1
    end
    """

    # Connect to bluetooth and upload file
    b = Bluetooth()
    await b.connect(
        print_response_handler=lambda s: print(s),
    )

    print("Uploading script")

    await b.upload_file(graphics_script, "graphics.lua")
    await b.upload_file(main_script, "main.lua")
    await b.send_reset_signal()

    # Wait until a keypress
    await ainput("")

    await b.send_break_signal()
    await b.disconnect()


loop = asyncio.new_event_loop()
loop.run_until_complete(main())
