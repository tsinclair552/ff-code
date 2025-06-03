FF Troubleshooting - "no attribute 'shape'" error

Export from CapCut with defaults - success

Export from QuickTime Player as MOV - fail

Handbrake:

General Presets - 
Very Fast 1080p30 - Fail
Fast 1080p30 - Fail
Fast 1080p30 - Fail
HQ 1080p30 Surround - Fail
Super HQ 1080p30 Surround - Fail

Web Presets - 
Creator 1080p60 - Fail
Social 25 MB 30 Seconds 1080p60 - Fail

Device Presets - 
Android 1080p30 - Fail
Apple 1080p50 Surround - Fail
Chromecast 1080p60 Surround - Fail
Playstation 1080p30 Surround - Fail
Roku 1080p30 Surround - Fail

Hardware Presets - 
H.265 Apple VideoToolbox 1080p - Fail

Professional Presets - 
Production Proxy 1080p - Succeed
Production Standard - Succeed

Both CapCut and Handbrake will apparently work. The advantage of using Hanbrake is that I can create
batch jobs more easily.

Test on folder the.zaira.effect
(at least one of these files will error out)

Process:
- Click on Source in HandBrake
- Select the folder with the videos
- Select Add To Queue -> Add all titles to queue
- Change preset to Production Proxy 1080p
- Click Browse to select an output folder
- Click Start.

NOTE: if the video is greater than 1080p then it will be reduced to 1080p

Using Production Standard will also work and retain resolution but will create larger files
Handbrake will also preserve the original filename by default.

