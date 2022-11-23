# Zigbee TS011F Power Strip EdgeDriver

This is my personal SmartThings edge driver for a cheap multi-outlet power strip I found on amazon

## Installing the driver

If you would like to use this driver, you can install
it from my channel of drivers by clicking
[here](https://api.smartthings.com/invitation-web/accept?id=68aadc42-709e-4cff-989f-e3bb760c32f8)
to accept my invite, enroll your hub, and install any of my drivers including this one.

## Supported Devices

See the [fingerprints](fingerprints.yml) for the set of devices that can currently be used
with this driver.

## Adding a device

Once you have installed this driver to your hub, you should be able to use the `Scan Nearby` option
under `Add Device` in the SmartThings mobile app, and proceed to join the devices normally.

## Running tests

The SmartThings Edge Drivers test framework is described in detail
[here](https://developer-preview.smartthings.com/edge-device-drivers/driver_tests.html).  To run
the tests you will need to set up your `LUA_PATH` as described in the
[SmartThings docs](https://github.com/SmartThingsCommunity/SmartThingsEdgeDrivers#lua_path). You
can then run the tests provided by navigating to the `src` directory and running
`lua test/test_XXX.lua`.