"""
Simulates the auto-exposure control loop used in camera.auto()
"""

from aioconsole import ainput
from frameutils import Bluetooth
import asyncio
import matplotlib.pyplot as plot
from matplotlib.ticker import EngFormatter


async def main():

    lua_script = """
    while true do
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

    (red_plot,) = input_axis.plot(frame_count, r_brightness_values, "r", label="red")
    (green_plot,) = input_axis.plot(
        frame_count, g_brightness_values, "g", label="green"
    )
    (blue_plot,) = input_axis.plot(frame_count, b_brightness_values, "b", label="blue")
    (average_plot,) = input_axis.plot(
        frame_count, average_brightness_values, "k", label="average"
    )
    input_axis.set_ylim([-0.05, 1.05])
    input_axis.set_ylabel("Brightness")
    input_axis.legend(loc="upper left")

    (shutter_plot,) = shutter_axis.plot(
        frame_count, shutter_values, "r", label="shutter"
    )
    (gain_plot,) = gain_axis.plot(frame_count, gain_values, "b", label="gain")

    shutter_axis.set_ylim([0, 1000])
    shutter_axis.set_ylabel("Setpoints")
    shutter_axis.legend(loc="upper left")
    shutter_axis.yaxis.set_major_formatter(EngFormatter(sep=""))
    gain_axis.set_ylim([0, 260])
    gain_axis.legend(loc="upper right")

    (error_plot,) = error_axis.plot(frame_count, error_values)
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

        error_axis.set_xlim([0, len(frame_count)])

        plot.pause(0.001)

    # Connect to bluetooth and upload file
    b = Bluetooth()
    await b.connect(print_response_handler=update_graph)
    await b.send_break_signal()
    print("Uploading script")
    await b.upload_file(lua_script, "main.lua")
    await b.send_reset_signal()

    # Wait until a keypress
    await ainput("Press enter to exit")

    await b.send_break_signal()
    await b.disconnect()


loop = asyncio.new_event_loop()
loop.run_until_complete(main())

plot.show()
