"""
Tests the Frame specific Lua libraries over Bluetooth.
"""

import asyncio, sys
from frameutils import Bluetooth
import sounddevice as sd
import numpy as np

audio_buffer = b""
expected_samples = 0


def receive_data(data):
    global audio_buffer
    global expected_samples
    audio_buffer += data
    print(
        f"Received {str(len(audio_buffer))} / {str(int(expected_samples))} bytes",
        end="\r",
    )


async def record_and_play(b: Bluetooth, seconds, sample_rate, bit_depth):
    global audio_buffer
    global expected_samples

    print(f"Recording {seconds} seconds at {sample_rate/1000}kHz {bit_depth}bit")
    await b.send_lua(f"frame.microphone.record({seconds}, {sample_rate}, {bit_depth})")
    await asyncio.sleep(0.5)

    expected_samples = seconds * sample_rate * (bit_depth / 8)

    audio_buffer = b""

    mtu = b.max_data_payload()

    while len(audio_buffer) < expected_samples:
        await b.send_lua(f"frame.bluetooth.send(frame.microphone.read({mtu}))")

    print("\nConverting to audio")

    # Convert audio bytes to a NumPy array of type int8
    if bit_depth == 16:
        audio_data = np.frombuffer(audio_buffer, dtype=np.int16)
    if bit_depth == 8:
        audio_data = np.frombuffer(audio_buffer, dtype=np.int8)
    if bit_depth == 4:
        raise NotImplementedError("TODO")

    # Convert it to float32 which is what sounddevice expects for playback
    audio_data = audio_data.astype(np.float32)

    # Normalize the 8-bit data range (-128 to 127) to (-1, 1) for playback
    audio_data /= np.iinfo(np.int8).max

    sd.play(audio_data, sample_rate)

    sd.wait()


async def main():
    b = Bluetooth()

    await b.connect(data_response_handler=receive_data)

    await record_and_play(b, 5, 8000, 8)

    await record_and_play(b, 2.5, 16000, 8)

    await record_and_play(b, 2.5, 16000, 16)

    await b.disconnect()


asyncio.run(main())
