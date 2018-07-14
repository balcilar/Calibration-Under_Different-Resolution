function [points3d] = mytriangulate(points1, points2, camMatrix1, camMatrix2)
%% written by Muhammet Balcilar,France
% all rights reserved
%% muhammetbalcilar@gmail.com

for i = 1:size(points1,1)
    points3d(i, :) = triangulateOnePoint(points1(i,:), points2(i,:),camMatrix1, camMatrix2);    
end

end

function point3d = triangulateOnePoint(point1, point2, P1, P2)

% do the triangulation
A = zeros(4, 4);
A(1:2,:) = point1' * P1(3,:) - P1(1:2,:);
A(3:4,:) = point2' * P2(3,:) - P2(1:2,:);

[~,~,V] = svd(A);
X = V(:, end);
X = X/X(end);

point3d = X(1:3)';

end