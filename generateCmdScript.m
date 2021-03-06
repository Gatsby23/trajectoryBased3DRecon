function generateCmdScript()
addpath('cvx');
cvx_setup;

fileName = 'cmd_killDevil';
fid = fopen(fileName, 'w');

for i = 100:20:500
fprintf( fid, 'bsub -q week -M16 matlab -nodisplay -nojvm -nosplash –singleCompThread -r "killDevil_MotionCaptureReconstructionDemo(%d)"\n',i );
end

fclose(fid);

system(sprintf('chmod +x %s', fileName));
system(sprintf('./%s', fileName));