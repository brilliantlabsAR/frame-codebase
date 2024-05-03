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
    target_exposure = 0.5
    shutter_kp = 1000
    gain_kp = 10
    shutter_limit = 6000

    -- Internal variables
    shutter = 0
    gain = 0

    while true do

        -- Get the histogram data
        h = frame.fpga.read(0x25, 45)

        red_0 = ((string.byte(h, 1) << 16) | (string.byte(h, 2) << 8) | string.byte(h, 3)) / 518400
        red_1 = ((string.byte(h, 4) << 16) | (string.byte(h, 5) << 8) | string.byte(h, 6)) / 518400
        red_2 = ((string.byte(h, 7) << 16) | (string.byte(h, 8) << 8) | string.byte(h, 9)) / 518400
        red_3 = ((string.byte(h, 10) << 16) | (string.byte(h, 11) << 8) | string.byte(h, 12)) / 518400
        red_4 = ((string.byte(h, 13) << 16) | (string.byte(h, 14) << 8) | string.byte(h, 15)) / 518400

        green_0 = ((string.byte(h, 16) << 16) | (string.byte(h, 17) << 8) | string.byte(h, 18)) / 518400
        green_1 = ((string.byte(h, 19) << 16) | (string.byte(h, 20) << 8) | string.byte(h, 21)) / 518400
        green_2 = ((string.byte(h, 22) << 16) | (string.byte(h, 23) << 8) | string.byte(h, 24)) / 518400
        green_3 = ((string.byte(h, 25) << 16) | (string.byte(h, 26) << 8) | string.byte(h, 27)) / 518400
        green_4 = ((string.byte(h, 28) << 16) | (string.byte(h, 29) << 8) | string.byte(h, 30)) / 518400

        blue_0 = ((string.byte(h, 31) << 16) | (string.byte(h, 32) << 8) | string.byte(h, 33)) / 518400
        blue_1 = ((string.byte(h, 34) << 16) | (string.byte(h, 35) << 8) | string.byte(h, 36)) / 518400
        blue_2 = ((string.byte(h, 37) << 16) | (string.byte(h, 38) << 8) | string.byte(h, 39)) / 518400
        blue_3 = ((string.byte(h, 40) << 16) | (string.byte(h, 41) << 8) | string.byte(h, 42)) / 518400
        blue_4 = ((string.byte(h, 43) << 16) | (string.byte(h, 44) << 8) | string.byte(h, 45)) / 518400

        average_0 = (red_0 + green_0 + blue_0) / 3
        average_1 = (red_1 + green_1 + blue_1) / 3
        average_2 = (red_2 + green_2 + blue_2) / 3
        average_3 = (red_3 + green_3 + blue_3) / 3
        average_4 = (red_4 + green_4 + blue_4) / 3

        -- Calculate error
        error = target_exposure - average_4

        if error > 0 then
        
            shutter = shutter + shutter_kp * error

            -- Prioritize shutter over gain when image is too dark
            if shutter >= shutter_limit then
                gain = gain + gain_kp * error
            end
        
        else

            -- When image is too bright, reduce gain first
            gain = gain + gain_kp * error

            if gain <= 0 then
                shutter = shutter + shutter_kp * error
            end

        end
                
        -- Limit the values
        if shutter > shutter_limit then shutter = shutter_limit end
        if shutter < 4 then shutter = 4 end

        if gain > 248 then gain = 248 end
        if gain < 0 then gain = 0 end

        -- Set the new values (rounded to nearest int)
        frame.camera.set_shutter(math.floor(shutter + 0.5))
        frame.camera.set_gain(math.floor(gain + 0.5))

        metrics = 'Data:'
        metrics = metrics..string.format('%.3f:%.3f:%.3f:%.3f:%.3f:', red_0, red_1, red_2, red_3, red_4)
        metrics = metrics..string.format('%.3f:%.3f:%.3f:%.3f:%.3f:', green_0, green_1, green_2, green_3, green_4)
        metrics = metrics..string.format('%.3f:%.3f:%.3f:%.3f:%.3f:', blue_0, blue_1, blue_2, blue_3, blue_4)
        metrics = metrics..string.format('%.3f:%.3f:%.3f:%.3f:%.3f:', average_0, average_1, average_2, average_3, average_4)
        metrics = metrics..shutter..':'..gain..':'..error
        print(metrics)

        frame.sleep(0.1)
    end
    """

    # Equivalent function to compare
    lua_script_b = """
    while true do
        -- Get current values
        e = frame.camera.auto{ metering = 'CENTER_WEIGHTED', 
                               target_exposure = 0.6, shutter_kp = 50, 
                               shutter_limit = 6000, gain_kp = 10 }

        metrics = 'Data:'

        -- TODO metrics = metrics..e['histogram']['r']['0']..':'

        metrics = metrics..e['shutter']..':'
        metrics = metrics..e['gain']..':'
        metrics = metrics..e['error']
        print(metrics)

        frame.sleep(0.1)
    end
    """

    # Data to plot
    frame_count = [0]

    shutter_values = [0]
    gain_values = [0]

    error_values = [0]

    # Set up the figure
    figure, (input_axis, shutter_axis, error_axis) = plot.subplots(3, 1)
    gain_axis = shutter_axis.twinx()
    figure.suptitle("Frame auto-exposure tuning tool")

    red_plot = input_axis.bar([0, 5, 10, 15, 20], [0,0,0,0,0], color='red', label='red')
    green_plot = input_axis.bar([1, 6, 11, 16, 21], [0,0,0,0,0], color='green', label='green')
    blue_plot = input_axis.bar([2, 7, 12, 17, 22], [0,0,0,0,0], color='blue', label='blue')
    average_plot = input_axis.bar([3, 8, 13, 18, 23], [0,0,0,0,0], color='black', label='average')
    input_axis.set_xticks([1.5, 6.5, 11.5, 16.5, 21.5])
    input_axis.set_xticklabels([-2,-1,0,1,2])
    input_axis.set_ylim([0,1.1])
    input_axis.set_ylabel("Brightness")
    input_axis.legend(loc="upper left")
    
    shutter_plot, = shutter_axis.plot(frame_count, shutter_values, 'r', label='shutter')
    gain_plot, = gain_axis.plot(frame_count, gain_values, 'b', label='gain')

    shutter_axis.set_ylim([0,17000])
    shutter_axis.set_ylabel("Setpoints")
    shutter_axis.legend(loc="upper left")
    shutter_axis.yaxis.set_major_formatter(EngFormatter(sep=""))
    gain_axis.set_ylim([0,260])
    gain_axis.legend(loc="upper right")

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

        # Increment frame counter and update x axis
        frame_count.append(max(frame_count) + 1)
        shutter_plot.set_xdata(frame_count)
        shutter_axis.set_xlim([0,len(frame_count)])
        gain_plot.set_xdata(frame_count)
        error_plot.set_xdata(frame_count)
        error_axis.set_xlim([0,len(frame_count)])

        # Append the returned data and update y axis
        for rect, h in zip(red_plot, [float(data[1]), float(data[2]), float(data[3]), float(data[4]), float(data[5])]):
            rect.set_height(h)
        for rect, h in zip(green_plot, [float(data[6]), float(data[7]), float(data[8]), float(data[9]), float(data[10])]):
            rect.set_height(h)
        for rect, h in zip(blue_plot, [float(data[11]), float(data[12]), float(data[13]), float(data[14]), float(data[15])]):
            rect.set_height(h)
        for rect, h in zip(average_plot, [float(data[16]), float(data[17]), float(data[18]), float(data[19]), float(data[20])]):
            rect.set_height(h)

        shutter_values.append(float(data[21]))
        shutter_plot.set_ydata(shutter_values)

        gain_values.append(float(data[22]))
        gain_plot.set_ydata(gain_values)

        error_values.append(float(data[23]))
        error_plot.set_ydata(error_values)

        plot.pause(0.001)

    # Connect to bluetooth and upload file
    b = Bluetooth()
    await b.connect(print_response_handler=update_graph)
    await b.send_break_signal()
    print("Uploading script")
    await b.send_lua("f=frame.file.open('main.lua', 'w')")
    for line in lua_script_a.splitlines():
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
