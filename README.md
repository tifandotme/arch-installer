# Arch Linux Installer
How to run:
```bash
curl -LO https://raw.githubusercontent.com/ifananvity/master/install.sh
bash install.sh
```

Detailed documentation coming soon

## launch.ks
This kOS script will automate your launch with a [gravity turn](https://wiki.kerbalspaceprogram.com/wiki/Gravity_turn) maneuver in mind until your vessel in a parking circular orbit.

First off, make sure that your rocket meet these following criteria in order to achieve the best possible ascent profile:
1. Have an atleast 1.4 of TWR.
2. Aerodynamically stable.
3. Structurally stable.
This one is especially important, because sometimes the rocket can go back and forth when the heading system is set. So I highly recommend to enable rigid attachment and/or autostrut for your parts.

Run the program alongside it's 2 parameter: `run launch(a, b)`. Where **a** is your target orbit altitude (in km) and **b** is your desired orbit inclination.
