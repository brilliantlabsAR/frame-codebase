"""
Simulates the auto-exposure control loop used in camera.auto()
"""
from aioconsole import ainput
from frameutils import Bluetooth
import asyncio
import matplotlib.pyplot as plot
from matplotlib.ticker import EngFormatter

async def main():

    # Lua script of auto-exposure algorithm (under the hood)
    lua_script_a = """
    -- Configuration
    target_exposure = 0.0
    shutter_kp = 0.1
    shutter_limit = 6000
    gain_kp = 1
    gain_limit = 248

    -- Internal variables (defaults)
    shutter = 3000
    gain = 0

    while true do
        -- Get current values
        brightness = frame.fpga.read(0x25, 6)
        center_r = string.byte(brightness, 1) / 64 - 2
        center_g = string.byte(brightness, 2) / 64 - 2
        center_b = string.byte(brightness, 3) / 64 - 2
        average_r = string.byte(brightness, 4) / 64 - 2
        average_g = string.byte(brightness, 5) / 64 - 2
        average_b = string.byte(brightness, 6) / 64 - 2

        spot = (center_r + center_g + center_b) / 3
        average = (average_r + average_g + average_b) / 3
        center_weighted = (spot + spot + average) / 3

        -- Calculate error
        error = target_exposure - center_weighted

        if error > 0 then
        
            shutter = shutter + (shutter_kp * shutter) * error

            -- Prioritize shutter over gain when image is too dark
            if shutter >= shutter_limit then
                gain = gain + gain_kp * error
            end
        
        else

            -- When image is too bright, reduce gain first
            gain = gain + gain_kp * error

            if gain <= 0 then
                shutter = shutter + (shutter_kp * shutter) * error
            end

        end
                
        -- Limit the values
        if shutter > shutter_limit then shutter = shutter_limit end
        if shutter < 4 then shutter = 4 end

        if gain > gain_limit then gain = gain_limit end
        if gain < 0 then gain = 0 end

        -- Set the new values (rounded to nearest int)
        frame.camera.set_shutter(math.floor(shutter + 0.5))
        frame.camera.set_gain(math.floor(gain + 0.5))

        print('Data:'..average_r..':'..average_g..':'..average_b..':'..center_weighted..':'..shutter..':'..gain..':'..error)

        frame.sleep(0.1)
    end
    """

    # Equivalent function to compare
    lua_script_b = """
    while true do
        -- Get current values
        e = frame.camera.auto { metering = 'CENTER_WEIGHTED', exposure = 0.0, 
                                shutter_kp = 0.1, shutter_limit = 6000,
                                gain_kp = 1, gain_limit = 248 }

        metrics = 'Data:'
        metrics = metrics..e['brightness']['matrix']['r']..':'
        metrics = metrics..e['brightness']['matrix']['g']..':'
        metrics = metrics..e['brightness']['matrix']['b']..':'
        metrics = metrics..e['brightness']['center_weighted_average']..':'
        metrics = metrics..e['shutter']..':'
        metrics = metrics..e['gain']..':'
        metrics = metrics..e['error']
        print(metrics)

        frame.sleep(0.1)
    end
    """

    lua_script_c = """
    while true do
        -- Get current values
        e = frame.camera.auto { }

        metrics = 'Data:'
        metrics = metrics..e['brightness']['matrix']['r']..':'
        metrics = metrics..e['brightness']['matrix']['g']..':'
        metrics = metrics..e['brightness']['matrix']['b']..':'
        metrics = metrics..e['brightness']['center_weighted_average']..':'
        metrics = metrics..e['shutter']..':'
        metrics = metrics..e['gain']..':'
        metrics = metrics..e['error']
        print(metrics)

        frame.sleep(0.1)
    end
    """

    # Data to plot
    frame_count = [0]

    r_brightness_values = [0]
    g_brightness_values = [0]
    b_brightness_values = [0]

    average_brightness_values = [0]
    shutter_values = [0]
    gain_values = [0]

    error_values = [0]

    # Set up the figure
    figure, (input_axis, shutter_axis, error_axis) = plot.subplots(3, 1, sharex=True)
    gain_axis = shutter_axis.twinx()
    figure.suptitle("Frame auto-exposure tuning tool")
    
    red_plot, = input_axis.plot(frame_count, r_brightness_values, 'r', label='red')
    green_plot, = input_axis.plot(frame_count, g_brightness_values, 'g', label='green')
    blue_plot, = input_axis.plot(frame_count, b_brightness_values, 'b', label='blue')
    average_plot, = input_axis.plot(frame_count, average_brightness_values, 'k', label='average')
    input_axis.set_ylim([-0.05, 1.05])
    input_axis.set_ylabel("Brightness")
    input_axis.legend(loc="upper left")
    
    shutter_plot, = shutter_axis.plot(frame_count, shutter_values, 'r', label='shutter')
    gain_plot, = gain_axis.plot(frame_count, gain_values, 'b', label='gain')

    shutter_axis.set_ylim([0, 17000])
    shutter_axis.set_ylabel("Setpoints")
    shutter_axis.legend(loc="upper left")
    shutter_axis.yaxis.set_major_formatter(EngFormatter(sep=""))
    gain_axis.set_ylim([0 ,260])
    gain_axis.legend(loc="upper right")

    error_plot, = error_axis.plot(frame_count, error_values)
    error_axis.set_ylim([-0.1, 2.1])
    error_axis.set_xlabel("Frame")
    error_axis.set_ylabel("Error")

    # Function that will update the graph when new data arrives
    def update_graph(response: str):
        if response.startswith("Data:") == False:
            # print(response) # Enable for easier debugging
            return

        data = response.split(":")

        # Increment frame counter
        frame_count.append(max(frame_count) + 1)

        # Append the returned data
        r_brightness_values.append(float(data[1]))
        g_brightness_values.append(float(data[2]))
        b_brightness_values.append(float(data[3]))
        average_brightness_values.append(float(data[4]))
        shutter_values.append(float(data[5]))
        gain_values.append(float(data[6]))
        error_values.append(float(data[7]))

        red_plot.set_xdata(frame_count)
        green_plot.set_xdata(frame_count)
        blue_plot.set_xdata(frame_count)
        average_plot.set_xdata(frame_count)
        shutter_plot.set_xdata(frame_count)
        gain_plot.set_xdata(frame_count)
        error_plot.set_xdata(frame_count)

        red_plot.set_ydata(r_brightness_values)
        green_plot.set_ydata(g_brightness_values)
        blue_plot.set_ydata(b_brightness_values)
        average_plot.set_ydata(average_brightness_values)
        shutter_plot.set_ydata(shutter_values)
        gain_plot.set_ydata(gain_values)
        error_plot.set_ydata(error_values)

        error_axis.set_xlim([0,len(frame_count)])

        plot.pause(0.001)

    # Connect to bluetooth and upload file
    b = Bluetooth()
    await b.connect(print_response_handler=update_graph)
    await b.send_break_signal()
    print("Uploading script")
    await b.send_lua("f=frame.file.open('main.lua', 'w')")
    for line in lua_script_c.splitlines():
        await b.send_lua(f'f:write("{line.replace("'", "\\'")}\\n");print(nil)', await_print=True)
    await b.send_lua("f:close()")
    await asyncio.sleep(0.1)
    await b.send_reset_signal()

    # Wait until a keypress
    await ainput("Press enter to exit")

    await b.send_break_signal()
    await b.disconnect()


loop = asyncio.new_event_loop()
loop.run_until_complete(main())

plot.show()
