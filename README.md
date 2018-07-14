# Stereo Camera Calibration under Different Resolution

In this project we modified existing Matlab toolbox's code to get the stereo calibration run under different resolution cameras. Especially if you want to work with multiple different camera, you should calibrate them. For instance infrared camera and RBG camera, or as how our demo was on you can calibrate up down mounthed high resolution standart USB camera and relatively low resolution Pan-Tilt-Zoom (PTZ) camera.  

Unfortunately neither Matlab's nor OpenCV's does not give us an opportunity to calibrate such a both two very different kind of camera. The following figure shows one of our provided 7 pair of calibration board images from USB and PZT camera. The USB camera has 1920x1080 resolution but PZT has just 720x480.

![Sample image](Outputs/1stframes.bmp?raw=true "Title")

We slightly modified ```estimateCameraParameters.m``` and ```rectifyStereoImages.m ``` functions of Matlab Toolboxes. You can find them on that repository. Also we provided demo script. You can run it with following command.

```
> Demo
```
then you can take following outputs as a results. You can see extrinsic parameter, rectified image pair and position of cameras relative to 1st checkerboard points, their ground truth and also estimated positions from triangulation of both camera.

![Sample image](Outputs/results.bmp?raw=true "Title")

Here is the calibration parameters of USB camera;

```
K1 =  

    1157.0         0    931.2
         0    1147.4    376.0
         0         0    1
R1 =
   -0.9972    0.0177   -0.0732
   -0.0328   -0.9770    0.2108
   -0.0678    0.2126    0.9748

T1 =
   58.6597
  -30.2059
  613.0425
  ```
  
  And also here is PZT camera parameters
  
  ```
  K2 =
  876.9470         0  326.4428
         0  776.9896  196.5821
         0         0    1.0000
         
R2 =
   -0.9997    0.0114   -0.0231
   -0.0137   -0.9944    0.1043
   -0.0218    0.1046    0.9943
   
T2 =
   93.4428
  101.1229
  584.6069  
  
  ```
  
  
