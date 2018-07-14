%% Modified by Muhammet Balcilar, France, muhammetbalcilar@gmail.com
% rectifyStereoImages Rectifies a pair of stereo images.
%   [J1, J2] = rectifyStereoImages(I1, I2, stereoParams) undistorts and rectifies
%   I1 and I2, a pair of truecolor or grayscale stereo images. stereoParams
%   is a stereoParameters object containing the parameters of the 
%   stereo camera system. J1 and J2 are the rectified images.
% 
%   [J1, J2] = rectifyStereoImages(I1, I2, tform1, tform2) rectifies I1 and
%   I2, by applying projective transformations tform1 and tform2 returned
%   by the estimateUncalibratedRectification function.
%
%   [...] = rectifyStereoImages(..., interp) specifies interpolation
%   method to use. interp can be one of the strings 'nearest',
%   'linear', or 'cubic'. The default value for interp is 'linear'.
% 
%   [...] = rectifyStereoImages(..., Name, Value) specifies additional 
%   name-value pairs described below:
% 
%   'OutputView'   Determines the size of the rectified images J1 and J2.
%                  Possible values are:
%                    'full'  - J1 and J2 include all pixels from I1 and I2
%                    'valid' - J1 and J2 are cropped to the size of the 
%                              largest common rectangle containing valid pixels
% 
%                  Default: 'valid'
% 
%   'FillValues'   An array containing one or several fill values.
%                  Fill values are used for output pixels when the
%                  corresponding inverse transformed location in the
%                  input image is completely outside the input image
%                  boundaries.
% 
%                  If I1 and I2 are 2-D grayscale images then 'FillValues' 
%                  must be a scalar. If I1 and I2 are a truecolor images,
%                  then 'FillValues' can be a scalar or a 3-element vector
%                  of RGB values. 
%
%                  Default: 0
%
%   Class Support
%   -------------
%   The class of I1 and I2 can be uint8, uint16, int16, double, single.
%   I1 and I2 must be the of the same class. J1 and J2 are the same class 
%   as I1 and I2. stereoParams must be a stereoParameters object. tform1
%   and tform2 must be 3-by-3 single or double projective transform matrices
%   or projective2d objects.
%
%   Example
%   -------
%   % Specify images containing a checkerboard for calibration
%   imageDir = fullfile(toolboxdir('vision'), 'visiondata', ...
%       'calibration', 'stereo');
%   leftImages = imageDatastore(fullfile(imageDir, 'left'));
%   rightImages = imageDatastore(fullfile(imageDir, 'right'));
%  
%   % Detect the checkerboards
%   [imagePoints, boardSize] = detectCheckerboardPoints(...
%       leftImages.Files, rightImages.Files);
%  
%   % Specify world coordinates of checkerboard keypoints
%   squareSizeInMillimeters = 108;
%   worldPoints = generateCheckerboardPoints(boardSize, squareSizeInMillimeters);
%  
%   % Calibrate the stereo camera system
%   stereoParams = estimateCameraParameters(imagePoints, worldPoints);
% 
%   % Read in the images
%   I1 = readimage(leftImages, 1);
%   I2 = readimage(rightImages, 1);
% 
%   % Rectify the images using 'full' output view
%   [J1_full, J2_full] = rectifyStereoImages(I1, I2, stereoParams, ...
%     'OutputView', 'full');
% 
%   % Display the result
%   figure; 
%   imshow(stereoAnaglyph(J1_full, J2_full));
%
%   % Rectify the images using 'valid' output view. This is most suitable
%   % for computing disparity.
%   [J1_valid, J2_valid] = rectifyStereoImages(I1, I2, stereoParams, ...
%     'OutputView', 'valid');
% 
%   % Display the result
%   figure; 
%   imshow(stereoAnaglyph(J1_valid, J2_valid));
% 
%   See also estimateCameraParameters, estimateUncalibratedRectification,
%     disparity, reconstructScene, stereoParameters, cameraCalibrator,
%     stereoCameraCalibrator

% Copyright 2014 MathWorks, Inc.

% References:
%
% G. Bradski and A. Kaehler, "Learning OpenCV : Computer Vision with
% the OpenCV Library," O'Reilly, Sebastopol, CA, 2008.

%#codegen

function [rectifiedImage1, rectifiedImage2] = my_rectifyStereoImages(I1, ...
    I2, stereoParams, varargin)

%vision.internal.inputValidation.validateImagePair(I1, I2, 'I1', 'I2');

if ~isa(stereoParams, 'stereoParameters')
    narginchk(4, inf);
    t1 = stereoParams;
    t2 = varargin{1};
        
    [tform1, tform2, interp, outputView, fillValues] = ...
        parseInputsUncalibrated(I1, t1, t2, varargin{2:end});

    [rectifiedImage1, rectifiedImage2] = rectifyUncalibrated(I1, I2, ...
        tform1, tform2, interp, fillValues, outputView);
else
    [interp, outputView, fillValues] = parseInputsCalibrated(...
        I1, stereoParams, varargin{:});
    
    [rectifiedImage1, rectifiedImage2] = rectifyStereoImagesImpl(stereoParams, ...
        I1, I2, interp, fillValues, outputView);
end

%--------------------------------------------------------------------------
function [interp, outputView, fillValues] = ...
    parseInputsCalibrated(image1, stereoParams, varargin)

validateStereoParameters(stereoParams);

if isempty(coder.target)
    [interp, outputView, fillValues] = ...
        vision.internal.inputValidation.parseUndistortRectifyInputsMatlab(...
        'rectifyStereoImages', image1, @validateOutputViewPartial, varargin{:});
else
    [interp, outputView, fillValues] = ...
        vision.internal.inputValidation.parseUndistortRectifyInputsCodegen(...
        image1, 'rectifyStereoImages', 'valid', varargin{:});
end
fillValues = vision.internal.inputValidation.scalarExpandFillValues(...
    fillValues, image1);

%--------------------------------------------------------------------------
function [tform1, tform2, interp, outputView, fillValues] = ...
    parseInputsUncalibrated(I1, t1, t2, varargin)

validateTransform(t1, 'tform1');
validateTransform(t2, 'tform2');

if isnumeric(t1)
    tform1 = projective2d(t1);
    tform2 = projective2d(t2);
else
    tform1 = t1;
    tform2 = t2;
end

if isempty(coder.target)
    [interp, outputView, fillValues] = ...
        vision.internal.inputValidation.parseUndistortRectifyInputsMatlab(...
        'rectifyStereoImages', I1, @validateOutputViewPartial, varargin{:});
else
    [interp, outputView, fillValues] = ...
        vision.internal.inputValidation.parseUndistortRectifyInputsCodegen(...
        I1, 'rectifyStereoImages', 'valid', varargin{:});
end

%--------------------------------------------------------------------------
function TF = validateTransform(tform, varName)
validateattributes(tform, {'double', 'single', 'projective2d'}, {}, ...
    mfilename, varName); %#ok<EMCA>

if ~isa(tform, 'projective2d')
    validateattributes(tform, {'double', 'single'}, ...
        {'real', 'nonsparse', 'size', [3, 3]}, mfilename, varName); %#ok<EMCA>    
end

TF = true;
    
%--------------------------------------------------------------------------
function TF = validateStereoParameters(params)
validateattributes(params, {'stereoParameters'}, ...
    {'scalar'}, mfilename, 'stereoParams'); %#ok<EMCA>
TF = true;

%--------------------------------------------------------------------------
function outputView = validateOutputViewPartial(outputView)
outputView = ...
    validatestring(outputView, {'full', 'valid'}, mfilename, 'OutputView'); %#ok<EMCA>

%--------------------------------------------------------------------------
function [J1, J2] = rectifyUncalibrated(I1, I2, tform1, tform2, interp, ...
    fillValues, outputView)
% Compute the transformed location of image corners.
outPts = zeros(8, 2);
numRows = size(I1, 1);
numCols = size(I1, 2);
inPts = [1, 1; 1, numRows; numCols, numRows; numCols, 1];
outPts(1:4,1:2) = transformPointsForward(tform1, inPts);
numRows = size(I2, 1);
numCols = size(I2, 2);
inPts = [1, 1; 1, numRows; numCols, numRows; numCols, 1];
outPts(5:8,1:2) = transformPointsForward(tform2, inPts);

xSort   = sort(outPts(:,1));
ySort   = sort(outPts(:,2));
xLim = zeros(1, 2);
yLim = zeros(1, 2);
if strcmp(outputView, 'valid')
    % Compute the common rectangular area of the transformed images.    
    xLim(1) = ceil(xSort(4)) - 0.5;
    xLim(2) = floor(xSort(5)) + 0.5;
    yLim(1) = ceil(ySort(4)) - 0.5;
    yLim(2) = floor(ySort(5)) + 0.5;
else % full
    xLim(1) = ceil(xSort(1)) - 0.5;
    xLim(2) = floor(xSort(8)) + 0.5;
    yLim(1) = ceil(ySort(1)) - 0.5;
    yLim(2) = floor(ySort(8)) + 0.5;
end

width   = xLim(2) - xLim(1) - 1;
height  = yLim(2) - yLim(1) - 1;
outputViewRef = imref2d([height, width], xLim, yLim);

% Transform the images.
J1 = imwarp(I1, tform1, interp, 'OutputView', outputViewRef, 'FillValues', ...
    fillValues);
J2 = imwarp(I2, tform2, interp, 'OutputView', outputViewRef, 'FillValues', ...
    fillValues);
