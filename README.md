# Stereo Camera Calibration under Different Resolution

In this project we modified existing Matlab toolbox's code to get the stereo calibration run under different resolution cameras. Especially if you want to work with multiple different camera, you should calibrate them. For instance infrared camera and RBG camera, or as how our demo was on you can calibrate up down mounthed high resolution standart USB camera and relatively low resolution Pan-Tilt-Zoom (PTZ) camera.  

Unfortunately neither Matlab's nor OpenCV's does not give us an opportunity to calibrate such a both two very different kind of camera. The following figure shows one of our provided 7 pair of calibration board images from USB and PZT camera. The USB camera has 1920x1080 resolution but PZT has just 720x480.

![Sample image](Outputs/1stframes.bmp?raw=true "Title")

We slightly modified ```estimateCameraParameters.m```and ```rectifyStereoImages.m ``` functions of Matlab Tooloboxes. You can find them on that repository. Also we provided demo script. ou can run it with following command.

```
> Demo
```
then you can 
