"""
Simulates the auto-exposure control loop used in camera.auto()
"""
from aioconsole import ainput
from frameutils import Bluetooth
import asyncio
import matplotlib.pyplot as plot

async def main():

    # Lua script of auto-exposure algorithm
    lua_script = """
    -- Configuration
    setpoint_brightness = 0.686
    exposure_kp = 1600
    gain_kp = 30

    -- Internal variables
    exposure = 0
    gain = 0

    while true do
        -- Get current values
        brightness = fpga.read(25, 6)
        r = string.byte(brightness, 4)
        g = string.byte(brightness, 5)
        b = string.byte(brightness, 6)
        average = frame.camera.get_metering('average')

         -- Calculate error
        error = setpoint_brightness - average

        if error > 0 then
        
            -- Prioritize exposure over gain when image is too dark
            exposure = exposure + exposure_kp * error

            if exposure >= 800 then
                gain = gain + gain_kp * error
            end
        
        else

            -- When image is too bright, reduce gain first
            gain = gain + gain_kp * error

            if gain <= 0 then
                exposure = exposure + exposure_kp * error
            end

        end

        -- Limit the values
        if exposure > 800 then exposure = 800 end
        if exposure < 20 then exposure = 20 end

        if gain > 255 then gain = 255 end
        if gain < 0 then gain = 0 end

        -- Set the new values (rounded to nearest int)
        frame.camera.set_exposure(math.floor(exposure + 0.5))
        frame.camera.set_gain(math.floor(gain + 0.5))

        print('Data:'..r..':'..g..':'..b..':'..average..':'..exposure..':'..gain..':'..error)

        frame.sleep(0.1)
    end
    """

    # Data to plot
    frame_count = [0]

    r_brightness_values = [0]
    g_brightness_values = [0]
    b_brightness_values = [0]

    average_brightness_values = [0]
    exposure_values = [0]
    gain_values = [0]

    error_values = [0]

    # Set up the figure
    figure, (input_axis, setpoint_axis, error_axis) = plot.subplots(3, 1, sharex=True)
    figure.suptitle("Frame auto-gain/exposure tuning tool")
    
    red_plot, = input_axis.plot(frame_count, r_brightness_values, 'r', label='red')
    green_plot, = input_axis.plot(frame_count, g_brightness_values, 'g', label='green')
    blue_plot, = input_axis.plot(frame_count, b_brightness_values, 'b', label='blue')
    average_plot, = input_axis.plot(frame_count, average_brightness_values, 'k', label='average')
    input_axis.set_ylim([0,1])
    input_axis.set_ylabel("Brightness")
    input_axis.legend(loc="upper left")
    
    exposure_plot, = setpoint_axis.plot(frame_count, exposure_values, 'r', label='exposure')
    gain_plot, = setpoint_axis.plot(frame_count, gain_values, 'b', label='gain')
    setpoint_axis.set_ylim([0,850])
    setpoint_axis.set_ylabel("Setpoints")
    setpoint_axis.legend(loc="upper left")

    error_plot, = error_axis.plot(frame_count, error_values)
    error_axis.set_ylim([-1,1])
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
        exposure_values.append(float(data[5]))
        gain_values.append(float(data[6]))
        error_values.append(float(data[7]))

        red_plot.set_xdata(frame_count)
        green_plot.set_xdata(frame_count)
        blue_plot.set_xdata(frame_count)
        average_plot.set_xdata(frame_count)
        exposure_plot.set_xdata(frame_count)
        gain_plot.set_xdata(frame_count)
        error_plot.set_xdata(frame_count)

        red_plot.set_ydata(r_brightness_values)
        green_plot.set_ydata(g_brightness_values)
        blue_plot.set_ydata(b_brightness_values)
        average_plot.set_ydata(average_brightness_values)
        exposure_plot.set_ydata(exposure_values)
        gain_plot.set_ydata(gain_values)
        error_plot.set_ydata(error_values)

        error_axis.set_xlim([0,len(frame_count)])

        plot.pause(0.001)

    # Connect to bluetooth and upload file
    b = Bluetooth()
    await b.connect(print_response_handler=update_graph)
    await b.send_break_signal()
    await b.send_lua("f=frame.file.open('main.lua', 'w')")
    for line in lua_script.splitlines():
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
