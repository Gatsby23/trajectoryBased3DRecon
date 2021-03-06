function MotionCaptureReconstructionDemo(filename)

% Motion capture demo
% Paper: "3D Reconstruction of a Moving Point from a Series of 2D Projections (ECCV)"
% Authors: Hyun Soo Park, Takaaki Shiratori, Iain Matthews, and Yaser Sheikh
% Please refer to
% http://www.andrew.cmu.edu/user/hyunsoop/eccv2010/eccv_project_page.html

% This script reads motion capture data, generates a random camera trajectory, reconstructs point trajectories, and animate the motion.
% Ex> MotionCaptureReconstructionDemo('stand_data.mat')
% You can set amount of occlusion, frame rate, noise level of correspondences, and the number of basis.
% When you do not know the number of basis, you can set nBasis = -1. (Let the system decide.)

filename = './motionCapture/walk_data.mat';
%  filename = './motionCapture/stand_data.mat';
occlusion = 0.0; % 20% occlusion
framerate = 1; % 100% of full frame rate
noise_level = 0.0; % noise of image measurement
nBasis = 240; % the number of basis is determined by the cross validation.

% ----------------------------------------------------------------------
s = RandStream('mcg16807','Seed',0);
RandStream.setDefaultStream(s);
addpath('F:\Enliang\library_64\cvx_mip');
cvx_setup;

Data = load(filename);
X0 = Data.X(:,1:floor(1/framerate):end);
Y0 = Data.Y(:,1:floor(1/framerate):end);
Z0 = Data.Z(:,1:floor(1/framerate):end);
X0 = X0-mean(X0(:));
Y0 = Y0-mean(Y0(:));
Z0 = Z0-mean(Z0(:));
T0 = Data.T(:,1:floor(1/framerate):end)-1;

for i = 1:size(X0,2)
    DSG{i} = [X0(:,i), Y0(:,i), Z0(:,i)];   %ground truth
end

% Camera trajectory generation
CameraTrajectory = 200* (rand(3, length(T0)) - 0.5);
% CameraTrajectory(3,:) = CameraTrajectory(3,:) + 100;
K = [1e+2 0 500; 0 1e+2 500; 0 0 1];

for iCamera = 1 : size(CameraTrajectory,2)
    % Camera parameter setting
    r3 = -CameraTrajectory(:,iCamera)'/norm(CameraTrajectory(:,iCamera));
    r1 = null(r3);  r1 = r1(:,1);
    r2 = Vec2Skew(r3) * r1;
    R = [r1'; r2'; r3];
    
    C{iCamera}.P = K*R*[eye(3) -CameraTrajectory(:,iCamera)];
    C{iCamera}.t = T0(iCamera);
    % 2D projection
    m = C{iCamera}.P * [X0(:,iCamera)'; Y0(:,iCamera)'; Z0(:,iCamera)'; ones(1,size(X0,1))];
    C{iCamera}.m = [m(1,:)./m(3,:); m(2,:)./m(3,:)]';
    C{iCamera}.m = C{iCamera}.m + noise_level*randn(size(C{iCamera}.m));
    C{iCamera}.R = R;
    C{iCamera}.C = CameraTrajectory(:,iCamera);
    C{iCamera}.K = K;    
end

% Occlusion
for iPoint = 1 : size(X0,1)
    pm = randperm(length(T0));
    for iOcc = 1 : floor(length(T0)*occlusion)
        C{pm(iOcc)}.m(iPoint,:) = [NaN NaN];
    end
end

% Reconstruct point trajectories
[Traj] = TrajectoryReconstruction(C, nBasis); % Reconstruction w/o predefined number of basis

for i = 1 : size(Traj{1},1)
    ds = [];
    for j = 1 : length(Traj)
        ds = [ds; Traj{j}(i,:)];
    end
    DS{i} = ds;
end

% evaluation
error = evaluateError(DS, DSG);


% Animate result
figure(1), clf;
for i = 1 : length(DS)
%     d = DSG{i};
%     DSG{i} = repmat(d(1,:), size(d,1),1);
    if i == 1 
        h = DrawMocapHuman(DS{i}, 'b-x'); hold on
        h2 = DrawMocapHuman(DSG{i}, 'r-x'); hold on
    else
        DrawMocapHuman(DS{i}, 'b-x', h); hold on
        DrawMocapHuman(DSG{i}, 'r-x', h2);hold on
    end
    grid on, axis off, axis vis3d, axis equal, set(gcf, 'color', 'w');
    axis([-400 400 -400 400 -50 80])
    drawnow
     pause(0.01);
end



