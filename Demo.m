%% Written by Muhammet Balcilar, France, muhammetbalcilar@gmail.com
% All rights reserved
%%%%%%%%%%%%

clear all
close all

file1 = {'Inputs/USBCamera1.bmp',...
    'Inputs/USBCamera2.bmp',...
    'Inputs/USBCamera3.bmp',...
    'Inputs/USBCamera4.bmp',...
    'Inputs/USBCamera5.bmp',...
    'Inputs/USBCamera6.bmp',...
    'Inputs/USBCamera7.bmp',...
    };
file2={'Inputs/PTZCamera1.bmp',...
    'Inputs/PTZCamera2.bmp',...
    'Inputs/PTZCamera3.bmp',...
    'Inputs/PTZCamera4.bmp',...
    'Inputs/PTZCamera5.bmp',...
    'Inputs/PTZCamera6.bmp',...
    'Inputs/PTZCamera7.bmp',...
    };



% Detect checkerboards in images
[imagePoints{1}, boardSize, imagesUsed1] = detectCheckerboardPoints(file1);
[imagePoints{2}, boardSize, imagesUsed2] = detectCheckerboardPoints(file2);

% Generate world coordinates of the checkerboards keypoints
squareSize = 25;  % in units of 'mm'
worldPoints = generateCheckerboardPoints(boardSize, squareSize);


[param, pairsUsed, estimationErrors] = my_estimateCameraParameters(imagePoints, worldPoints, ...
    'EstimateSkew', false, 'EstimateTangentialDistortion', false, ...
    'NumRadialDistortionCoefficients', 2, 'WorldUnits', 'mm', ...
    'InitialIntrinsicMatrix', [], 'InitialRadialDistortion', []);


% View reprojection errors
h1=figure; showReprojectionErrors(param);

% Visualize pattern locations
h2=figure; showExtrinsics(param, 'CameraCentric');

% Display parameter estimation errors
displayErrors(estimationErrors, param);

% You can use the calibration data to undistort images
I1 = imread(file1{1});
I2 = imread(file2{1});

D1 = undistortImage(I1, param.CameraParameters1);
D2 = undistortImage(I2, param.CameraParameters2);

figure;subplot(1,2,1);imshow(I1);
subplot(1,2,2);imshow(I2);
figure;subplot(1,2,1);imshow(D1);
subplot(1,2,2);imshow(D2);

% You can use the calibration data to rectify stereo images.
[J1, J2] = my_rectifyStereoImages(I1, I2, param,'OutputView','full');
figure;imshowpair(J1,J2,'falsecolor','ColorChannels','red-cyan');


% select displayed checkeroard detection point grount truth 
% estimated point positions and camera positions.
cno=1;

Wpoints=[worldPoints zeros(size(worldPoints,1),1)];
figure;hold on;
axis vis3d; axis image;
grid on;
plot3(Wpoints(:,1),Wpoints(:,2),Wpoints(:,3),'b.','MarkerSize',20)

K1=param.CameraParameters1.IntrinsicMatrix';
R1=param.CameraParameters1.RotationMatrices(:,:,cno)';
T1=param.CameraParameters1.TranslationVectors(cno,:)';

Lcam=K1*[R1 T1];

K2=param.CameraParameters2.IntrinsicMatrix';
R2=param.CameraParameters2.RotationMatrices(:,:,cno)';
T2=param.CameraParameters2.TranslationVectors(cno,:)';


Rcam=K2*[R2 T2];

[points3d] = mytriangulate(imagePoints{1}(:,:,cno), imagePoints{2}(:,:,cno), Lcam,Rcam );
plot3(points3d(:,1),points3d(:,2),points3d(:,3),'r.')


% referencePoint(0,0,0)= R*Camera+T, So Camera=-inv(R)*T;
CL=-R1'*T1;
CR=-R2'*T2;

plot3(CR(1),CR(2),CR(3),'gs','MarkerFaceColor','g');
plot3(CL(1),CL(2),CL(3),'cs','MarkerFaceColor','c');
legend({'ground truth point locations','Calculated point locations','Camera2 position','Camera1 Position'});


% calculate relative distance from camera1 to camera2 in two different way
dist_1=norm(param.TranslationOfCamera2)
dist_2=norm(CR-CL)




% set the projection plane. I just project all pixel on to Z=0 plane
Z=0;

O=zeros(size(I1));
% remapping
for i=1:size(I1,1)
    i
    for j=1:size(I1,2)
        X=inv([Lcam(:,1:2) [-1*j;-1*i;-1]])*(-Z*Lcam(:,3)-Lcam(:,4));
        P=Rcam*[X(1);X(2);Z;1];
        P=fix(P/P(end));
        if P(1)>0 & P(2)<size(I2,1) & P(2)>0 & P(1)<size(I2,2)
            O(i,j,:)=I2(P(2),P(1),:);
        end
    end
end
figure;imshow(uint8(O))
figure;imshowpair(I1,uint8(O),'falsecolor','ColorChannels','red-cyan');










