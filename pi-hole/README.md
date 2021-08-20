# SmartThings Edge PiHole Driver

This repository contains the package necessary to create a SmartThings Edge driver to
communicate with and control a [PiHole](https://pi-hole.net/) on your network.

## Installing this driver

It is not necessary for you to do anything with this source code if all you want is to
use this driver on your SmartThings account.  Instead, you can use the version of the driver
that I have already uploaded (and potentially get future updates if I make them), by
accepting the invite to my channel
[here](https://api.smartthings.com/invitation-web/accept?id=68aadc42-709e-4cff-989f-e3bb760c32f8)

Once you have accepted the invite, enrolled your hub, and installed the driver, you can move on
to adding the device.

## Adding a PiHole device

Once you have this driver installed on your hub, you will need to add the PiHole device on your
network to start using it.  Navigate in the mobile app to the Add Device page and select
`Scan Nearby`.  You should see a device named `PiHole` show up pretty quick.  From there you can
exit the join screen and the device should be there.

**Note:** Currently this driver will only ever find a single device.  That is, once that first
device is created it will not create another unless you delete that first device.  If your network
setup includes multiple PiHoles discovery code changes would be necessary to support that with
this driver.

Now navigate to the device card for your PiHole and click the ⋮ menu in the upper right and
go to `Settings`. You should see two settings.  First you can enter the IP Address of your PiHole
(this is just a string and is expected to be an IPv4 string like "192.168.1.150").  Next you will
need to enter the `Webpassword` needed to communicate with the PiHole via it's REST API.  You can
get this by sshing into your PiHole and running:

```console
sudo cat /etc/pihole/setupVars.conf | grep WEBPASSWORD
WEBPASSWORD=fec68f59abaea0538d579df9303ac022ba8f8628f000e2cdbd68606b5a1a67a2
```

Enter everything after the equal sign into the Webpassword setting in SmartThings

Once those 2 settings are in, you are almost good to go.  Due to a current issue with syncing
custom capabilities you will have to reboot your hub.  But after the reboot, you should be able to
turn your PiHole on and off and see some stats about how many requests your PiHole is blocking or
not.

## Uploading this package for yourself

While you don't need to touch this code if all you want is to use the driver, this is also intended
to be something you can use as an example.  This driver uses Custom Capabilities that are published
by me and thus use my personal namespace of `pianobook11249`.  These capabiliteis can be used as
is, but if you want to go through the process of creating your own version of this driver package,
you can do so by creating your own version of the custom capabilities and presentation using the
definitions that are present in this repository in the `capabilities` directory.  Once you have your
own published, you can find/replace `pianobook11249` in this repository with your personal
namespace.  From there you can follow the normal process for packaging and installing a SmartThings
Edge Driver.

