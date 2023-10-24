#!/usr/bin/env python3
"""
An application to communicate to the Frame over Bluetooth.
"""

import asyncio
import sys
import os
import tty
import termios

from bleak import BleakClient, BleakScanner
from bleak.backends.characteristic import BleakGATTCharacteristic
from bleak.backends.device import BLEDevice
from bleak.backends.scanner import AdvertisementData

SERVICE = "7a230001-5475-a6a4-654c-8431f6ad49c4"
TX_CHARACTERISTIC = "7a230002-5475-a6a4-654c-8431f6ad49c4"
RX_CHARACTERISTIC_UUID = "7a230003-5475-a6a4-654c-8431f6ad49c4"


def service_filter(_: BLEDevice, adv: AdvertisementData):
    return SERVICE in adv.service_uuids


def disconnect_handler(_: BleakClient):
    print("\nDisconnected")
    sys.exit(0)


def data_received_handler(_: BleakGATTCharacteristic, data: bytearray):
    print(data.decode(), end="", flush=True)


async def connect():
    device = await BleakScanner.find_device_by_filter(service_filter)

    if device is None:
        print("No device found")
        sys.exit(1)

    async with BleakClient(device, disconnected_callback=disconnect_handler) as client:
        await client.start_notify(RX_CHARACTERISTIC_UUID, data_received_handler)
        service = client.services.get_service(SERVICE)
        transmit_characteristic = service.get_characteristic(TX_CHARACTERISTIC)

        print("Connected")

        while True:
            input_string = input()
            await client.write_gatt_char(transmit_characteristic, input_string.encode())


if __name__ == "__main__":
    asyncio.run(connect())
