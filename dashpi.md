# Raspberry pi dashboard

## You'll need

+ Raspberry Pi
+ Dashing Service

## Preparing the system

We'll install raspbian into our SD card. You can follow instructions from here [http://www.raspberrypi.org/downloads](http://www.raspberrypi.org/downloads)

### Setting up NTP

This will sync the time time with ubuntu ntp server

```bash
sudo apt-get install ntpdate
sudo ntpdate -u ntp.ubuntu.com
```

### Update the OS

```bash
sudo apt-get update
sudo apt-get upgrade
sudo apt-get dist-upgrade
```

### Install some useful software

```bash
sudo apt-get install git-core vim
```

### Updating the RaspberryPi’s firmware

To update the firmware to the latest version, we’ll use Hexxeh’s rpi-update script.

```bash
sudo wget http://goo.gl/1BOfJ -O /usr/bin/rpi-update && sudo chmod +x /usr/bin/rpi-update
sudo rpi-update
```

### Configure your monitor resolution

Find the TV supported modes, here I search for 1920x1080 60hz. That is `hdmi_mode=16` on the `hdmi_group=1`
Select the group depending on the results of the supported modes

```bash
tvservice -d edid
edidparser edid
```

Add this to the `/boot/config.txt` file

```
hdmi_group=1    # CEA=1, DMT=2
hdmi_mode=16
disable_overscan=1
```
Also we want to disable overscan to prevent black lines on the edges of the screen. This may produce that your images gets cropped.
The best solution is disable overscan in the tv. *Check the display menu options (it may be called "just scan", "screen fit", "HD size", "full pixel", "unscaled", "dot by dot", "native" or "1:1)*

## Start the browser on boot

### Install Chromium

First, you’ll want to install Chromium on your RaspberryPi.
I tried several browsers alternatives, midori, iceweasel, kweb.

```bash
sudo apt-get install chromium-browser
```

Configure chromium so it start maximized to the size of our tv

Edit `~/.config/chromium/Default/Preferences` and edit the following section
```json
"window_placement": {
   "bottom": 1080,
   "left": 0,
   "maximized": true,
   "right": 1920,
   "top": 0,
   "work_area_bottom": 1080,
   "work_area_left": 0,
   "work_area_right": 1920,
   "work_area_top": 0
}
```

### X server

Install x11 server utils to controll video parameters and unclutter to remove the mouse from over our dashboard

```bash
sudo apt-get install x11-xserver-utils unclutter
```

Create a script in `/etc/pi/dashboard` with the code that will run chromium in kiosk mode

```bash
#!/bin/sh
chromium-browser \
--kiosk \
--ignore-certificate-errors \
--disable-restore-session-state \
--start-maximized \
--incognito \
http://dash.platan.us/dashing/dashboards
```

Add execution permition to the script
```bash
chmod +x dashboard
```

Add this code to your `~/.xinitrc`
```bash
unclutter &

xset s off         # don't activate screensaver
xset -dpms         # disable DPMS (Energy Star) features.
xset s noblank     # don't blank the video device

exec /home/pi/dashboard
```

To start on boot we will create a init script in `/etc/init.d/dashboard`
```bash
sudo touch /etc/init.d/dashboard
sudo chmod 755 /etc/init.d/dashboard
```

Now add this code to the script
```bash
#! /bin/sh
# /etc/init.d/dashboard
case "$1" in
  start)
    echo "Starting dashboard"
    # run application you want to start
    /bin/su pi -c xinit
    ;;
  stop)
    echo "Stopping dashboard"
    # kill application you want to stop
    killall xinit
    ;;
  *)
    echo "Usage: /etc/init.d/dashboard {start|stop}"
    exit 1
    ;;
esac

exit 0
```

We need to register the script to start on boot as kiosk
```bash
sudo update-rc.d dashboard defaults
```

## Turn off automatically

I wanted to be able to turn on and off the tv using the CEC standard via HDMI, but the tv we bought wasn't CEC compilant :(  
One alternative was to turn of the HDMI signal with a cronjob and set the tv to auto turn off after a few minutes without signal.  
But the power coming from the USB port stops flowing when the tv is off so I'd prefer to shut down the PI from a cronjob.

Add it to the root cronjob service running `sudo crontab -e` and adding

```
0       20      *       *       1,2,3,4,5 /sbin/shutdown -h now
```

## References
- http://alexba.in/blog/2013/01/04/raspberrypi-quickstart/
- https://gist.github.com/petehamilton/5705374
- http://www.fusonic.net/en/blog/2013/07/31/diy-info-screen-using-raspberry-pi-dashing/
- http://blogs.wcode.org/2013/09/howto-boot-your-raspberry-pi-into-a-fullscreen-browser
- https://github.com/MobilityLab/TransitScreen/wiki/Raspberry-Pi
- http://nyxi.eu/blog/2013/04/15/raspbian-libcec/
- http://weblogs.asp.net/bleroy/archive/2013/04/10/getting-your-raspberry-pi-to-output-the-right-resolution.aspx
- http://elinux.org/R-Pi_Troubleshooting
