function [cameraParams, imagesUsed, estimationErrors] = my_estimateCameraParameters(varargin)
%% Modified by Muhammet Balcilar, France, muhammetbalcilar@gmail.com

%estimateCameraParameters Calibrate a single camera or a stereo camera
%
%   [cameraParams, imagesUsed, estimationErrors] =
%   estimateCameraParameters(imagePoints, worldPoints) estimates intrinsic,
%   extrinsic, and distortion parameters of a single camera.
% 
%   Inputs:
%   -------
%   imagePoints - an M-by-2-by-P array of [x,y] intrinsic image coordinates 
%                 of keypoints on the calibration pattern. M > 3 
%                 is the number of keypoints in the pattern. P > 2 is the
%                 number of images containing the calibration pattern.
%
%   worldPoints - an M-by-2 array of [x,y] world coordinates of 
%                 keypoints on the calibration pattern. The pattern 
%                 must be planar, so all z-coordinates are assumed to be 0.
%   
%   Outputs:
%   --------
%   cameraParams     - a cameraParameters object containing the camera parameters. 
%
%   imagesUsed       - a P-by-1 logical array indicating which images were 
%                      used to estimate the camera parameters. P > 2 is the
%                      number of images containing the calibration pattern. 
%
%   estimationErrors - a cameraCalibrationErrors object containing the 
%                      standard errors of the estimated camera parameters.
% 
%   [stereoParams, pairsUsed, estimationErrors] =
%   estimateCameraParameters(imagePoints, worldPoints) estimates parameters
%   of a stereo camera.
% 
%   Inputs:
%   -------
%   imagePoints - An M-by-2-by-numPairs-by-2 array of [x,y] intrinsic image 
%                 coordinates of keypoints of the calibration pattern. M > 3 
%                 is the number of keypoints in the pattern. numPairs is the
%                 number of stereo pairs of images containing the
%                 calibration pattern. imagePoints(:,:,:,1) are the points 
%                 from camera 1, and imagePoints(:,:,:,2) are the points 
%                 from camera 2.
%
%   worldPoints - An M-by-2 array of [x,y] world coordinates of 
%                 keypoints on the calibration pattern. The pattern 
%                 must be planar, so all z-coordinates are assumed to be 0.
% 
%   Outputs:
%   --------
%   stereoParams     - A stereoParameters object containing the parameters
%                      of the stereo camera system. 
%
%   pairsUsed        - A numPairs-by-1 logical array indicating which image
%                      pairs were used to estimate the camera parameters. 
%                      numPairs > 2 is the number of image pairs containing
%                      the calibration pattern. 
%
%   estimationErrors - A stereoCalibrationErrors object containing the 
%                      standard errors of the estimated stereo parameters. 
%
%   cameraParams = estimateCameraParameters(..., Name, Value)  
%   specifies additional name-value pair arguments described below.
% 
%   Parameters include:
%   -------------------
%   'WorldUnits'                      A string that describes the units in 
%                                     which worldPoints are specified.
%
%                                     Default: 'mm'
%
%   'EstimateSkew'                    A logical scalar that specifies whether 
%                                     image axes skew should be estimated.
%                                     When set to false, the image axes are
%                                     assumed to be exactly perpendicular.
%
%                                     Default: false
%
%   'NumRadialDistortionCoefficients' 2 or 3. Specifies the number of radial 
%                                     distortion coefficients to be estimated. 
%
%                                     Default: 2
%
%   'EstimateTangentialDistortion'    A logical scalar that specifies whether 
%                                     tangential distortion should be estimated.
%                                     When set to false, tangential distortion 
%                                     is assumed to be negligible.
%
%                                     Default: false
%
%   'InitialIntrinsicMatrix'          A 3-by-3 matrix containing the initial
%                                     guess for the camera intrinsics. If the 
%                                     value is empty, the initial intrinsic 
%                                     matrix is computed using linear least 
%                                     squares.
%
%                                     Default: []
%
%   'InitialRadialDistortion'         A vector of 2 or 3 elements containing
%                                     the initial guess for radial distortion 
%                                     coefficients. If the value is empty, 
%                                     0 is used as the initial value for all
%                                     the coefficients.
%                                     
%                                     Default: []
%
%   Class Support
%   -------------
%   worldPoints and imagePoints must be double or single.
%
%   Notes
%   -----
%   estimateCameraParameters computes a homography between the world points
%   and the points detected in each image. If the homography computation
%   fails for any image, the function will issue a warning and it will not
%   use the points from that image for estimating the camera parameters. To
%   determine which images were actually used for estimating the parameters,
%   use imagesUsed output.
%
%   Example 1: Single Camera Calibration
%   ------------------------------------
%   % Create a set of calibration images.
%   images = imageDatastore(fullfile(toolboxdir('vision'), 'visiondata', ...
%     'calibration', 'fishEye'));
%   imageFileNames = images.Files;
%
%   % Detect calibration pattern.
%   [imagePoints, boardSize] = detectCheckerboardPoints(imageFileNames);
%
%   % Generate world coordinates of the corners of the squares.
%   squareSize = 29; % millimeters
%   worldPoints = generateCheckerboardPoints(boardSize, squareSize);
%
%   % Calibrate the camera.
%   params = estimateCameraParameters(imagePoints, worldPoints);
%
%   % Visualize calibration accuracy.
%   figure;
%   showReprojectionErrors(params);
%
%   % Visualize camera extrinsics.
%   figure;
%   showExtrinsics(params);
%   drawnow;
%
%   % Plot detected and reprojected points.
%   figure; 
%   imshow(imageFileNames{1}); 
%   hold on
%   plot(imagePoints(:, 1, 1), imagePoints(:, 2, 1), 'go');
%   plot(params.ReprojectedPoints(:, 1, 1), params.ReprojectedPoints(:, 2, 1), 'r+');
%   legend('Detected Points', 'ReprojectedPoints');
%   hold off
%
%   Example 2: Stereo Calibration
%   -----------------------------
%   % Specify calibration images.
%   leftImages = imageDatastore(fullfile(toolboxdir('vision'), 'visiondata', ...
%       'calibration', 'stereo', 'left'));
%   rightImages = imageDatastore(fullfile(toolboxdir('vision'), 'visiondata', ...
%       'calibration', 'stereo', 'right'));
%
%   % Detect the checkerboards.
%   [imagePoints, boardSize] = ...
%     detectCheckerboardPoints(leftImages.Files, rightImages.Files);
%
%   % Specify world coordinates of checkerboard keypoints.
%   squareSize = 108; % in millimeters
%   worldPoints = generateCheckerboardPoints(boardSize, squareSize);
%
%   % Calibrate the stereo camera system.
%   params = estimateCameraParameters(imagePoints, worldPoints);
%
%   % Visualize calibration accuracy.
%   figure;
%   showReprojectionErrors(params);
%
%   % Visualize camera extrinsics.
%   figure;
%   showExtrinsics(params);
%
%   See also cameraCalibrator, stereoCameraCalibrator, detectCheckerboardPoints, 
%     generateCheckerboardPoints, showExtrinsics, showReprojectionErrors,
%     undistortImage, cameraParameters, stereoParameters,
%     cameraCalibrationErrors, stereoCalibrationErrors

%   Copyright 2013-2014 MathWorks, Inc.

% References:
%
% [1] Z. Zhang. A flexible new technique for camera calibration. 
% IEEE Transactions on Pattern Analysis and Machine Intelligence, 
% 22(11):1330-1334, 2000.
%
% [2] Janne Heikkila and Olli Silven. A Four-step Camera Calibration Procedure 
% with Implicit Image Correction, IEEE International Conference on Computer
% Vision and Pattern Recognition, 1997.
%
% [3] Bouguet, JY. "Camera Calibration Toolbox for Matlab." 
% Computational Vision at the California Institute of Technology. 
% http://www.vision.caltech.edu/bouguetj/calib_doc/
%
% [4] G. Bradski and A. Kaehler, "Learning OpenCV : Computer Vision with
% the OpenCV Library," O'Reilly, Sebastopol, CA, 2008.


% Calibrate the camera

if iscell(varargin{1}) 
    itmp=varargin{1};    
    varargin{1}=itmp{2};    
    [imagePoints, worldPoints, worldUnits, cameraModel, calibrationParams] = ...
    parseInputs(varargin{:});
    imagePoints={itmp{1},imagePoints};    
else
    [imagePoints, worldPoints, worldUnits, cameraModel, calibrationParams] = ...
    parseInputs(varargin{:});
end

    
    


calibrationParams.shouldComputeErrors = (nargout >= 3);

if iscell(imagePoints) == 0 % single camera
    [cameraParams, imagesUsed, estimationErrors] = calibrateOneCamera(imagePoints, ...
        worldPoints, cameraModel, worldUnits, calibrationParams);
else % 2-camera stereo
%     [cameraParams, imagesUsed, estimationErrors] = calibrateTwoCameras(imagePoints,...
%         worldPoints, cameraModel, worldUnits, calibrationParams);

    shouldComputeErrors = calibrationParams.shouldComputeErrors;
    calibrationParams.shouldComputeErrors = false;


    [cameraParams1, imagesUsed1, estimationErrors1] = calibrateOneCamera(imagePoints{1}, ...
        worldPoints, cameraModel, worldUnits, calibrationParams);
    [cameraParams2, imagesUsed2, estimationErrors2] = calibrateOneCamera(imagePoints{2}, ...
        worldPoints, cameraModel, worldUnits, calibrationParams);
    
    imagesUsed = imagesUsed1 & imagesUsed2;
    cameraParams1 = removeUnusedExtrinsics(cameraParams1, imagesUsed, imagesUsed1);
    cameraParams2 = removeUnusedExtrinsics(cameraParams2, imagesUsed, imagesUsed2);

    % Compute the initial estimate of translation and rotation of camera 2
    [R, t] = estimateInitialTranslationAndRotation(cameraParams1, cameraParams2);

    cameraParams = stereoParameters(cameraParams1, cameraParams2, R, t);
    ip1=imagePoints{1};
    ip2=imagePoints{2};

    estimationErrors = refine(cameraParams, ip1(:, :, imagesUsed), ip2(:, :, imagesUsed), shouldComputeErrors);
    
end



%--------------------------------------------------------------------------
function [imagePoints, worldPoints, worldUnits, cameraModel, calibrationParams] = ...
    parseInputs(varargin)
parser = inputParser;
parser.addRequired('imagePoints', @checkImagePoints);
parser.addRequired('worldPoints', @checkWorldPoints);
parser.addParameter('WorldUnits', 'mm', @checkWorldUnits);
parser.addParameter('EstimateSkew', false, @checkEstimateSkew);
parser.addParameter('EstimateTangentialDistortion', false, ...
    @checkEstimateTangentialDistortion);
parser.addParameter('NumRadialDistortionCoefficients', 2, ...
    @checkNumRadialDistortionCoefficients);
parser.addParameter('InitialIntrinsicMatrix', [], @checkInitialIntrinsicMatrix);
parser.addParameter('InitialRadialDistortion', [], @checkInitialRadialDistortion);
parser.addParameter('ShowProgressBar', false, @checkShowProgressBar);

parser.parse(varargin{:});

imagePoints = parser.Results.imagePoints;
worldPoints = parser.Results.worldPoints;
if size(imagePoints, 1) ~= size(worldPoints, 1)
    error(message('vision:calibrate:numberOfPointsMustMatch'));
end

worldUnits  = parser.Results.WorldUnits;
cameraModel.EstimateSkew = parser.Results.EstimateSkew;
cameraModel.EstimateTangentialDistortion = ...
    parser.Results.EstimateTangentialDistortion;
initIntrinsics = double(parser.Results.InitialIntrinsicMatrix);
initRadial = double(parser.Results.InitialRadialDistortion);

if ~isempty(initRadial) && ...
        any(strcmp('NumRadialDistortionCoefficients', parser.UsingDefaults))
    cameraModel.NumRadialDistortionCoefficients = numel(initRadial);
else
    cameraModel.NumRadialDistortionCoefficients = ...
        parser.Results.NumRadialDistortionCoefficients;
end

if ~isempty(initRadial) && ...
        cameraModel.NumRadialDistortionCoefficients ~= numel(initRadial)
    error(message('vision:calibrate:numRadialCoeffsDoesntMatch', ...
        'InitialRadialDistortion', 'NumRadialDistortionCoefficients'));
end
calibrationParams.initIntrinsics = initIntrinsics;
calibrationParams.initRadial = initRadial;
calibrationParams.showProgressBar = parser.Results.ShowProgressBar;

%--------------------------------------------------------------------------
function tf = checkImagePoints(imagePoints)
validateattributes(imagePoints, {'double'}, ...
    {'finite', 'nonsparse', 'ncols', 2}, ...
    mfilename, 'imagePoints');

if ndims(imagePoints) == 4
    validateattributes(imagePoints, {'double'}, {'size', [nan, nan, nan, 2]}, ...
        mfilename, 'imagePoints');
end

if ndims(imagePoints) > 4
    error(message('vision:calibrate:imagePoints3Dor4D'));
end

if size(imagePoints, 3) < 2
    error(message('vision:calibrate:minNumPatterns'));
end

minNumPoints = 4;
if size(imagePoints, 1) < minNumPoints
    error(message('vision:calibrate:minNumImagePoints', minNumPoints-1));
end

tf = true;

%--------------------------------------------------------------------------
function tf = checkWorldPoints(worldPoints)
validateattributes(worldPoints, {'double'}, ...
    {'finite', 'nonsparse', '2d', 'ncols', 2}, ...
    mfilename, 'worldPoints');

minNumPoints = 4;
if size(worldPoints, 1) < minNumPoints
    error(message('vision:calibrate:minNumWorldPoints', minNumPoints-1));
end

tf = true;

%--------------------------------------------------------------------------
function tf = checkWorldUnits(worldUnits)
validateattributes(worldUnits, {'char'}, {'vector'}, mfilename, 'worldUnits');
tf = true;

%--------------------------------------------------------------------------
function tf = checkEstimateSkew(esitmateSkew)
validateattributes(esitmateSkew, {'logical'}, {'scalar'}, ...
    mfilename, 'EstimateSkew');
tf = true;

%--------------------------------------------------------------------------
function tf = checkEstimateTangentialDistortion(estimateTangential)
validateattributes(estimateTangential, {'logical'}, {'scalar'}, mfilename, ...
    'EstimateTangentialDistortion');
tf = true;

%--------------------------------------------------------------------------
function tf = checkNumRadialDistortionCoefficients(numRadialCoeffs)
validateattributes(numRadialCoeffs, {'numeric'}, ...
   {'scalar', 'integer', '>=', 2, '<=', 3}, ...
   mfilename, 'NumRadialDistortionCoefficients');
tf = true;

%--------------------------------------------------------------------------
function tf = checkInitialIntrinsicMatrix(K)
if ~isempty(K)
    validateattributes(K, {'single', 'double'}, ...
        {'real', 'nonsparse', 'finite', 'size', [3 3]}, ...
        mfilename, 'InitialIntrisicMatrix');
end
tf = true;

%--------------------------------------------------------------------------
function tf = checkInitialRadialDistortion(P)
if ~isempty(P)
    validateattributes(P, {'single', 'double'},...
        {'real', 'nonsparse', 'finite', 'vector'},...
        mfilename, 'InitialRadialDistortion');
    
    if numel(P) ~= 2
        validateattributes(P, {'single', 'double'}, {'numel', 3}, ...
            mfilename, 'InitialRadialDistortion');
    end
end
tf = true;

%--------------------------------------------------------------------------
function tf = checkShowProgressBar(showProgressBar)
vision.internal.inputValidation.validateLogical(showProgressBar, 'ShowProgressBar');
tf = true;

%--------------------------------------------------------------------------
function [cameraParams, imagesUsed, errors] = calibrateOneCamera(imagePoints, ...
    worldPoints, cameraModel, worldUnits, calibrationParams)

progressBar = createSingleCameraProgressBar(calibrationParams.showProgressBar);

% compute the initial "guess" of intrinisc and extrinsic camera parameters
% in closed form ignoring distortion
[cameraParams, imagesUsed] = computeInitialParameterEstimate(...
    worldPoints, imagePoints, cameraModel, worldUnits, ...
    calibrationParams.initIntrinsics, calibrationParams.initRadial);
imagePoints = imagePoints(:, :, imagesUsed);

progressBar.update();

% refine the initial estimate and compute distortion coefficients using
% non-linear least squares minimization
errors = refine(cameraParams, imagePoints, calibrationParams.shouldComputeErrors);
progressBar.update();
progressBar.delete();
%--------------------------------------------------------------------------
function [iniltialParams, validIdx] = computeInitialParameterEstimate(...
    worldPoints, imagePoints, cameraModel, worldUnits, initIntrinsics, initRadial)
% Solve for the camera intriniscs and extrinsics in closed form ignoring
% distortion.

[H, validIdx] = computeHomographies(imagePoints, worldPoints);

if isempty(initIntrinsics)
    V = computeV(H);
    B = computeB(V);
    A = computeIntrinsics(B);
else
    % initial guess for the intrinsics has been provided. No need to solve.
    A = initIntrinsics';
end

[rvecs, tvecs] = computeExtrinsics(A, H);

if isempty(initRadial)
    radialCoeffs = zeros(1, cameraModel.NumRadialDistortionCoefficients);
else
    radialCoeffs = initRadial;
end

iniltialParams = cameraParameters('IntrinsicMatrix', A', ...
    'RotationVectors', rvecs, ...
    'TranslationVectors', tvecs, 'WorldPoints', worldPoints, ...
    'WorldUnits', worldUnits, 'EstimateSkew', cameraModel.EstimateSkew,...
    'NumRadialDistortionCoefficients', cameraModel.NumRadialDistortionCoefficients,...
    'EstimateTangentialDistortion', cameraModel.EstimateTangentialDistortion,...
    'RadialDistortion', radialCoeffs);

%--------------------------------------------------------------------------
function H = computeHomography(imagePoints, worldPoints)
% Compute projective transformation from worldPoints to imagePoints

H = fitgeotrans(worldPoints, imagePoints, 'projective');
H = (H.T)';
H = H / H(3,3);


%--------------------------------------------------------------------------
function [homographies, validIdx] = computeHomographies(points, worldPoints)
% Compute homographies for all images

w1 = warning('Error', 'MATLAB:nearlySingularMatrix'); %#ok
w2 = warning('Error', 'images:maketform:conditionNumberofAIsHigh'); %#ok

numImages = size(points, 3);
validIdx = true(numImages, 1);
homographies = zeros(3, 3, numImages);
for i = 1:numImages
    try    
        homographies(:, :, i) = ...
            computeHomography(double(points(:, :, i)), worldPoints);
    catch 
        validIdx(i) = false;
    end
end
warning(w1);
warning(w2);
homographies = homographies(:, :, validIdx);
if ~all(validIdx)
    warning(message('vision:calibrate:invalidHomographies', ...
        numImages - size(homographies, 3), numImages));
end

if size(homographies, 3) < 2
    error(message('vision:calibrate:notEnoughValidHomographies'));
end

%--------------------------------------------------------------------------
function V = computeV(homographies)
% Vb = 0

numImages = size(homographies, 3);
V = zeros(2 * numImages, 6);
for i = 1:numImages
    H = homographies(:, :, i)';
    V(i*2-1,:) = computeLittleV(H, 1, 2);
    V(i*2, :) = computeLittleV(H, 1, 1) - computeLittleV(H, 2, 2);
end

%--------------------------------------------------------------------------
function v = computeLittleV(H, i, j)
    v = [H(i,1)*H(j,1), H(i,1)*H(j,2)+H(i,2)*H(j,1), H(i,2)*H(j,2),...
         H(i,3)*H(j,1)+H(i,1)*H(j,3), H(i,3)*H(j,2)+H(i,2)*H(j,3), H(i,3)*H(j,3)];

%--------------------------------------------------------------------------     
function B = computeB(V)
% lambda * B = inv(A)' * inv(A), where A is the intrinsic matrix

[~, ~, U] = svd(V);
b = U(:, end);

% b = [B11, B12, B22, B13, B23, B33]
B = [b(1), b(2), b(4); b(2), b(3), b(5); b(4), b(5), b(6)];

%--------------------------------------------------------------------------
function A = computeIntrinsics(B)
% Compute the intrinsic matrix

cy = (B(1,2)*B(1,3) - B(1,1)*B(2,3)) / (B(1,1)*B(2,2)-B(1,2)^2);
lambda = B(3,3) - (B(1,3)^2 + cy * (B(1,2)*B(1,3) - B(1,1)*B(2,3))) / B(1,1);
fx = sqrt(lambda / B(1,1));
fy = sqrt(lambda * B(1,1) / (B(1,1) * B(2,2) - B(1,2)^2));
skew = -B(1,2) * fx^2 * fy / lambda;
cx = skew * cy / fx - B(1,3) * fx^2 / lambda;
A = vision.internal.calibration.constructIntrinsicMatrix(fx, fy, cx, cy, skew);
if ~isreal(A)
    error(message('vision:calibrate:complexCameraMatrix'));
end

%--------------------------------------------------------------------------
function [rotationVectors, translationVectors] = ...
    computeExtrinsics(A, homographies)
% Compute translation and rotation vectors for all images

numImages = size(homographies, 3);
rotationVectors = zeros(3, numImages);
translationVectors = zeros(3, numImages); 
Ainv = inv(A);
for i = 1:numImages;
    H = homographies(:, :, i);
    h1 = H(:, 1);
    h2 = H(:, 2);
    h3 = H(:, 3);
    lambda = 1 / norm(Ainv * h1); %#ok
    
    % 3D rotation matrix
    r1 = lambda * Ainv * h1; %#ok
    r2 = lambda * Ainv * h2; %#ok
    r3 = cross(r1, r2);
    R = [r1,r2,r3];
    
    rotationVectors(:, i) = vision.internal.calibration.rodriguesMatrixToVector(R);
    
    % translation vector
    t = lambda * Ainv * h3;  %#ok
    translationVectors(:, i) = t;
end

rotationVectors = rotationVectors';
translationVectors = translationVectors';

%--------------------------------------------------------------------------
function [stereoParams, pairsUsed, errors] = calibrateTwoCameras(imagePoints,...
    worldPoints, cameraModel, worldUnits, calibrationParams)

imagePoints1 = imagePoints(:, :, :, 1);
imagePoints2 = imagePoints(:, :, :, 2);

showProgressBar = calibrationParams.showProgressBar;
progressBar = createStereoCameraProgressBar(showProgressBar);
calibrationParams.showProgressBar = false;

% Calibrate each camera separately
shouldComputeErrors = calibrationParams.shouldComputeErrors;
calibrationParams.shouldComputeErrors = false;
[cameraParameters1, imagesUsed1] = calibrateOneCamera(imagePoints1, ...
    worldPoints, cameraModel, worldUnits, calibrationParams);

progressBar.update();

[cameraParameters2, imagesUsed2] = calibrateOneCamera(imagePoints2, ...
    worldPoints, cameraModel, worldUnits, calibrationParams);

progressBar.update();

% Account for possible mismatched pairs
pairsUsed = imagesUsed1 & imagesUsed2;
cameraParameters1 = removeUnusedExtrinsics(cameraParameters1, pairsUsed, ...
    imagesUsed1);
cameraParameters2 = removeUnusedExtrinsics(cameraParameters2, pairsUsed, ...
    imagesUsed2);

% Compute the initial estimate of translation and rotation of camera 2
[R, t] = estimateInitialTranslationAndRotation(cameraParameters1, ...
    cameraParameters2);

stereoParams = stereoParameters(cameraParameters1, ...
    cameraParameters2, R, t);

errors = refine(stereoParams, imagePoints1(:, :, pairsUsed), ...
    imagePoints2(:, :, pairsUsed), shouldComputeErrors);

progressBar.update();
delete(progressBar);
%--------------------------------------------------------------------------
function cameraParams = removeUnusedExtrinsics(cameraParams, pairsUsed, ...
    imagesUsed)
% Remove the extrinsics corresponding to the images that were not used by
% the other camera
rotationVectors = zeros(numel(pairsUsed), 3);
rotationVectors(imagesUsed, :) = cameraParams.RotationVectors;

translationVectors = zeros(numel(pairsUsed), 3);
translationVectors(imagesUsed, :) = cameraParams.TranslationVectors;

cameraParams.setExtrinsics(...
    rotationVectors(pairsUsed, :), translationVectors(pairsUsed, :));

%--------------------------------------------------------------------------
% Compute the initial estimate of translation and rotation of camera 2
% relative to camera 1.
%--------------------------------------------------------------------------
function [R, t] = estimateInitialTranslationAndRotation(cameraParameters1, ...
    cameraParameters2)
% Now the number of images in both cameras should be the same.
numImages = cameraParameters1.NumPatterns;

rotationVectors = zeros(numImages, 3);
translationVectors = zeros(numImages, 3);

% For each set of extrinsics, compute R (rotation) and T (translation)
% between the two cameras.
for i = 1:numImages
    R = cameraParameters2.RotationMatrices(:, :, i)' * ...
        cameraParameters1.RotationMatrices(:, :, i);
    rotationVectors(i, :) = vision.internal.calibration.rodriguesMatrixToVector(R);
    translationVectors(i, :) = (cameraParameters2.TranslationVectors(i, :)' - ...
        R * cameraParameters1.TranslationVectors(i, :)')';
end

% Take the median rotation and translation as the initial guess.
r = median(rotationVectors, 1);
R = vision.internal.calibration.rodriguesVectorToMatrix(r)';
t = median(translationVectors, 1);

%--------------------------------------------------------------------------
function progressBar = createSingleCameraProgressBar(isEnabled)
messages = {'vision:calibrate:initialGuess', 'vision:calibrate:jointOptimization', ...
            'vision:calibrate:calibrationComplete'};
percentages = [0, 0.25, 1];        
progressBar = vision.internal.calibration.CalibrationProgressBar(isEnabled,...
    messages, percentages);

%--------------------------------------------------------------------------
function progressBar = createStereoCameraProgressBar(isEnabled)
messages = {'vision:calibrate:calibratingCamera1', ...
    'vision:calibrate:calibratingCamera2', ...
    'vision:calibrate:jointOptimization', 'vision:calibrate:calibrationComplete'};
percentages = [0, 0.25, .5, 1];        
progressBar = vision.internal.calibration.CalibrationProgressBar(isEnabled,...
    messages, percentages);



