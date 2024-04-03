exposure = 800
gain = 240

while true do
    resp = frame.camera.get_brightness()

    -- Calculate the average brightness
    r = resp['r']
    g = resp['g']
    b = resp['b']
    current = (r + g + b) / 3

    -- Calculate the error value
    target = 175
    error = target - current

    -- Apply P gains to exposure and gain
    exposure = exposure + (error * 1.5)
    gain = gain + (error * 0.3)

    -- Limit the values
    if exposure > 800 then exposure = 800 end
    if exposure < 20 then exposure = 20 end

    if gain > 255 then gain = 255 end
    if gain < 0 then gain = 0 end

    -- Set the new values
    frame.camera.set_exposure(math.floor(exposure + 0.5))
    frame.camera.set_gain(math.floor(gain + 0.5))

    print(gain)

    frame.sleep(0.1)
end