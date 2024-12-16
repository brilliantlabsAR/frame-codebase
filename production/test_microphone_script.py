from frameutils import Bluetooth
import asyncio
import numpy as np
import sounddevice as sd

audio_buffer = b""
done = False

lua_script = """
frame.microphone.start { bit_depth=16 }

local start_time = frame.time.utc()

while frame.time.utc() < start_time + 5 do 
    local len = (frame.bluetooth.max_length()//2)*2

    s=frame.microphone.read(len)

    if s==nil then 
        break 
    end

    if s~='' then 
        while true do 
            if (pcall(frame.bluetooth.send,'0'..s)) then 
                break 
            end 
        end 
    end
end

while true do 
    if (pcall(frame.bluetooth.send,'0')) then 
        break 
    end 
end 

frame.microphone.stop()
"""


def receive_data(data):
    global audio_buffer
    global done
    if len(data) > 1:
        audio_buffer += data[1:]

        print(
            f"                        Downloading microphone data {str(len(audio_buffer))} bytes      ",
            end="\r",
        )

    else:
        done = True


async def main():
    b = Bluetooth()
    await b.connect(data_response_handler=receive_data)
    await b.upload_file(lua_script, "main.lua")
    await b.send_reset_signal()

    while not done:
        await asyncio.sleep(0.1)

    await b.disconnect()

    audio_data = np.frombuffer(audio_buffer, dtype=np.int16)
    audio_data = audio_data.astype(np.float32)
    audio_data /= np.iinfo(np.int16).max

    sd.play(audio_data, 8000)
    sd.wait()


asyncio.run(main())
