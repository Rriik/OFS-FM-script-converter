# OFS script converter extension for rotary fuck machines

## Description
This is an [OpenFunscripter](https://github.com/OpenFunscripter/OFS) extension that can convert funscript patterns into power level variations suitable for any [buttplug.io-supported](https://iostindex.com/?filter0Type=Fucking%20Machine) rotary fuck machine.

Most penetrative fuck machines are built using piston motion systems. This makes them cheap to produce, but it also means their stroke position cannot be controlled in the same way that linear motion systems can. By contrast, most funscripts are made for masturbation sleeve devices, which can precisely adjust their stroke position. This allows them to be controlled effectively by alternating motion between 0-100 position values.

However, attempting to play back a regular funscript while connected to a rotary fuck machine results in irregular, uncontrollable bursts of power, which is very dangerous and can cause serious injuries. This extension aims to solve that problem, giving you control over the power level of your fuck machine while also attempting to match the machine's RPM to the rhythm of the action.

## Table of contents
- [Description](#description)
- [Features](#features)
- [GUI showcase](#gui-showcase)
- [Installation](#installation)
- [Usage](#usage)
  - [1. Make a copy of the funscript you want to convert](#1-make-a-copy-of-the-funscript-you-want-to-convert)
  - [2. Create your device profile](#2-create-your-device-profile)
  - [3. Adjust the conversion options](#3-adjust-the-conversion-options)
  - [4. Convert your funscript](#4-convert-your-funscript)
  - [5. Test the result](#5-test-the-result)
- [Guides](#guides)
  - [Measuring the RPM of devices](#measuring-the-rpm-of-devices)
  - [Setting up the funscript-to-machine connection](#setting-up-the-funscript-to-machine-connection)
  - [Designing scripts for fuck machines](#designing-scripts-for-fuck-machines)
  - [About peaks and troughs](#about-peaks-and-troughs)
- [Notes](#notes)

## Features
- A simple yet accurate cycle-time-to-power-level converter that only requires the min. and max. RPM of your device (with the toy attached) to work effectively
- Create and store custom device profiles for faster conversion
- A handy calculator utility helps you find the equivalent power level and RPM of your device profile for a given cycle duration (meaning the duration in the script between two peaks or two troughs)
- Conversion logic based fully on [peaks and troughs](#about-peaks-and-troughs) means not having to worry about how detailed the funscript patterns are
- Ample conversion options help you tailor the power level graph to better fit the content you are working on
- Quickly test your converted script by following the [funscript-to-machine setup guide below](#setting-up-the-funscript-to-machine-connection)!
- Developed for OFS v3

## GUI showcase
![image](https://github.com/Rriik/OFS-FM-script-converter/assets/132300166/677f2acc-462c-4c80-a900-29a3af9618a9)

## Installation
1. Download and extract the latest version of the extension from [Releases](https://github.com/Rriik/OFS-FM-script-converter/releases)
2. Copy the `FM script converter` directory and add it to the OFS extensions directory (`%appdata%/OFS3_data/extensions/`)
3. Start OpenFunscripter
4. In the `Extensions` tab, hover over the `FM script converter` list item and tick `Enabled` and `Show window`
5. Optionally, you can pin the extension window to the OFS GUI. I prefer dedicating the left side of the GUI to this extension.

## Usage
After completing the installation steps, you should be able to load up any OFS project and use the converter tool. Below are some instructions to get you started. Be sure to also check out the [guides](#guides) section to better understand how to use the tool.

### 1. Make a copy of the funscript you want to convert

This is important, as it will allow you to have a backup of the original script. It is also very convenient, as you can have multiple scripts loaded in an OFS project. So you can have both the original and the converted funscripts side by side, which should help you with further tweaking the converted script to your liking. You can name the converted script as `<original-script-name>_<device-profile-name>.funscript` for a nicer classification or if you want to tailor the scripts for each device profile.

### 2. Create your device profile

The FM script converter extension comes already pre-configured with a profile for the popular [Hismith Pro 1 fuck machine](https://www.hismith.com/en/hismith-brands/356-hismith-premium-sex-machine-app-control-with-wireless-remote.html) using a 1kg toy. I have created this profile after thoroughly benchmarking it using my Hismith and testing it on many scripts I have been making over the past half a year. I have also created [the guide below](#measuring-the-rpm-of-devices) to help you with the process of measuring the RPM values.

In addition to this, the extension provides a generic profile that can be tweaked to your liking. To store a custom profile, open the `main.lua` file in any text or code editor and add another entry in the `DeviceList` variable at the top of the file. A commented custom profile example is also available for convenience.

Device profiles are actually just linear growth functions described by the min. and max. RPM values you enter. You can also test this function with the built-in calculator to see the equivalent RPM for a certain power level or vice versa. This is because fuck machine controllers are typically built with a linear RPM step-increase in mind. Sometimes the linearity may taper off at the highest speed settings, but small RPM differences at high speeds are not as perceivable as they are at lower speeds.

### 3. Adjust the conversion options

The current set of conversion options primarily affects when the power level is and isn't recorded (in the form of an action on the converted funscript). You can choose whether to enable recording the power level on single peaks, single troughs, peak series and trough series.
![PeaksTroughs](https://github.com/Rriik/OFS-FM-script-converter/assets/132300166/085dbc31-da48-4b5c-b016-70bc5cd7e56f)
In addition to that, you can choose whether the converter should treat peak and trough series as dead zones where the device power level drops to 0. You also get to control how quickly the transition to and from a drop-off occurs. However, if the total series duration is shorter than the combined drop-off enter and exit intervals, only one drop-off action will be placed in the middle of the series duration instead. This feature is definitely more useful when used with longer duration pauses during thrusts, as rotary fuck machines tend to have mechanical inertia themselves and may take a brief moment to spool up or down. And finally, you can tell the converter to keep 0-position actions as-is, since these may obviously serve multiple purposes in your script.

Depending on which options you have enabled, the converted script can behave very differently.
![ConversionOptions](https://github.com/Rriik/OFS-FM-script-converter/assets/132300166/eaf264c9-e17a-4635-8427-3a04712db955)
Of course, this is just a quick mockup serving as an example. Longer and properly made scripts would have more nuance, but what this shows is that you can mix and match the options available to create more granularity in the power level fluctuations, drop the power level to 0 during peak and trough series, and more.

### 4. Convert your funscript

You can choose between converting the whole funscript or only the selected actions. To do so, simply load and select the script you want to convert, then press the buttons at the bottom of the conversion options menu.

**Note:** While this tool can effectively do most of the conversion work for you, it is not always a one-click-deploy solution. There may be specific segments of funscripts that need to be tweaked before or after applying the conversion. For example, transitional segments, orgasm moments, artificially boosted rhythms meant to create vibration in masturbation sleeves and other situations. Always double-check the whole script after conversion to ensure you are fully comfortable with the result. Remember, you should always have control over the machine, not the other way around.

### 5. Test the result

Finally, you can link your fuck machine and the OFS editor through middleware that implements the [buttplug.io protocol](https://buttplug.io/). I have also written [the guide below](#setting-up-the-funscript-to-machine-connection) to describe my own setup, if you want to learn more. If everything is configured correctly, you should be able to use the OFS video controls to synchronize the funscript and video with your device (make sure you have the converted funscript track selected in the editor).

## Guides

### Measuring the RPM of devices
The minimum and maximum RPM of a device should be measured with the toy attached to the device. Minimum RPM should be easy to measure by setting the device to run at 1% power from Intiface Central or other software that implements the [buttplug.io protocol](https://buttplug.io/).

For higher speed devices (200+ RPM), the cycle times get very small, and it can be challenging to measure 100% power RPM correctly. The peak RPM will also vary based on load mass and shape. Lighter toys have lower inertia (e.g. 500g vs. 1kg) and toys with a lower center of mass have less sway (e.g. short, tapered vs. long, top-heavy).

Perceived RPM also heavily depends on the device's motor and the friction between the toy and the human body. Devices with less powerful motors may struggle to deliver the torque needed for consistent lower speeds and may underperform at higher speeds when facing friction resistance. The resulting peak speeds can be within ± 5-10% of the manufacturer's stated max RPM.

Given all this, you have two options: either generally trust the device's stated max. RPM or test it yourself. In case of the former: take the stated max. RPM as the base value and try tweaking it in the extension's GUI to see how it synchronizes the machine and the scripts in real-world tests.

In case of the latter: measure the cycle times at different speeds using different toys and write the results on a spreadsheet. Test up to the highest speeds you can reliably measure. Then calculate the RPMs for each speed setting, plot the values and use trendlines to extrapolate the ideal peak RPM for you. You can create as many device profiles as you want by adding entries in the DeviceList as shown in the listed example.

### Setting up the funscript-to-machine connection

This guide may be different for your device or may change with the advent of new and better solutions in the future. But for now, it is a tried and tested solution and should give you an idea of what it takes to set this up.

You will need to install the following software (besides OFS):
- [Intiface Central](https://intiface.com/central/) - [buttplug.io](https://buttplug.io/) middleware, interfaces with your device
- [MultiFunPlayer](https://github.com/Yoooi0/MultiFunPlayer) - middleware, connects Intiface Central to OFS
- [Spacedesk](https://www.spacedesk.net/) - optional screen mirroring for remote play (PC to tablet, for example)

Below is a diagram showing how the different parts of the setup interact with one another.

![FuckMachineSystem](https://github.com/Rriik/OFS-FM-script-converter/assets/132300166/58e87f43-65d4-4b11-8a8e-baa04b17ba91)

You should also read through both the Intiface Central and MultiFunPlayer project documentation to better understand their feature sets. But as an overall checklist, these are the broad steps to follow:
1. Plug in and turn on your [buttplug.io-supported](https://iostindex.com/?filter0Type=Fucking%20Machine) rotary fuck machine
2. Turn on the Bluetooth connection on your computer (for desktop PCs, ensure you have a motherboard with WiFi/BT connectivity and that your external antenna is connected, if the motherboard comes with such an add-on)
3. Open Intiface Central, open the Devices section, start the server (big play button), then click on "Start Scanning". It should automatically find and connect to your machine
4. Open an OFS project that contains a converted script you wish to test (ensure you have the converted script selected in the editor)
5. In the OFS GUI, turn on the websocket server (View > Websocket API > "Server active" checkbox, keep the port number as is unless you have a custom websocket chain setup)
6. Open MultiFunPlayer. In the top right corner, select "Toggle media source" (+ button) and select OFS. Then click the "Connect" button below the OFS tab (play button). If done correctly, a graph of the funscript will also show up in the middle section of the window
7. In MultiFunPlayer, in the middle section, select the axis where the OFS websocket is linked. You should see the file name of the script you want to play and a websocket address above it (typically defaults to L0). **In the menu below the axis selection, you will see a green "Auto-home" button. Click that and set all the fields to 0, while leaving the Auto-home option enabled.** This is important, it ensures that when you pause the OFS video player, the machine also fully stops immediately. Otherwise, the auto-home behavior makes it default to a 50% power level and/or takes longer to stop it, which can be dangerous if you are unprepared
8. In MultiFunPlayer, in the bottom right corner, select "Add output" (+ button) and select Buttplug.io. Then click the "Connect" button below the Buttplug.io tab (play button). Select the dropdown arrow in the bottom right corner, then select the "Device map" menu. Fill in the dropdown boxes with your device information and the same axis you modified above. This is how the MultiFunPlayer window should look like at this point:

![image](https://github.com/Rriik/OFS-FM-script-converter/assets/132300166/85cb46d3-6707-4165-af57-1871eab1871d)

9. If you followed all the steps correctly, when you click the green + button to add the new device to the device map, nothing should happen (the machine should be at power level 0). And then, if you start playing the script in OFS, the machine should start being speed-controlled. If you then pause the video playback, it should immediately pause as well

After following these instructions, you're free to use Spacedesk or other software to enhance your play session by mirroring the OFS window to a tablet or other remote device and controlling the action from a distance.

### Designing scripts for fuck machines

While it may not be the focus of this extension, I think it may be worth pushing the funscript development community towards developing scripts for both masturbation sleeves and fuck machines. The [buttplug.io project](https://buttplug.io/) has only recently begun supporting smart fuck machines (start of 2023), so it is still an up-and-coming part of the fanbase, but I wholeheartedly encourage efforts to expand in this direction because I believe this would achieve the full potential of the funscripting ecosystem.

What I personally like doing is to create the "raw" penetration graph as the base funscript. I established certain rules for this too:

- The position value of an action should denote the penetrating percentage related to the full length of the shaft. 0 means no penetration, 100 means full penetration (entire shaft), 33 means one third penetration and so on.
- Actions should be placed (at least) at the beginning of every thrust and every pullback. Bonus points if you have the patience to make these frame-perfect and add intermediate positions to the thrust curve to match the content more closely.
- If there are noticeable pause periods (usually >100ms) between thrusts, actions with the same position value should be placed at the start and end of the pause period.
- Adding "standby" actions during non-penetrative parts of the content is up to the creator's preference, though I personally just like those periods to be fully unpowered (marked with 0-position actions).

These rules are meant to be usable also by linear motion fuck machines, which I find to be superior to rotary fuck machines as they can accurately reproduce the patterns you are designing (much like the masturbation sleeves). And although those machines may be capable of vibration patterns, that should be separated into a different funscript variation. The base funscript for fuck machines should instead aim for maximum device compatibility.

### About peaks and troughs
Peaks and troughs are mathematical local maxima and minima (points on a plot which are highest/lowest among their vicinity). In this case, they are the actions with the highest/lowest position value in their vicinity. The script analyzer respects the mathematical rules that dictate what should count as local extrema. This means that:

- a script with less than 2 actions or where all actions have the same position does not have local extrema
- multiple actions in a row that have the same position value will be considered local extrema if at least one fulfills the requirements for that
- the first and last actions (edges) of a script will be considered local extrema

To get a better sense of which actions are counted as peaks and troughs, you can check the debug section of the extension GUI. This section contains buttons that highlight the peaks and troughs by selecting the respective actions in the timeline.

## Notes

If you like this extension, please spread the word about it! May you happen to find the perfect configuration for your device? Be sure to share that knowledge in the comment sections where this is posted, or through GitHub issues (include your test results if possible)! Any feedback is welcome, so feel free to share your thoughts, suggestions for improvements or any bugs you may find.

Also, check out my other OFS extension project:
- [OFS script statistics](https://github.com/Rriik/OFS-script-statistics) - enables detailed script-wide statistics as an addition to the default statistics panel

A big thank-you goes to Dr. Sirius Graham Weldon for his contributions and support during the development of this tool.
