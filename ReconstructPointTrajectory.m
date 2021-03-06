function beta = ReconstructPointTrajectory(P, time_instance, measurement, sequence_length, K)

QQ = [];
qq = [];
Theta = [];
for iCamera = 1 : length(P)
    if( mod(iCamera, 100) == 0) 
        fprintf(1, ' %d%% is finished\n', round( iCamera/length(P)*100));
    end
    p = P{iCamera};
    skew = Vec2Skew([measurement(iCamera,:)';1]);
    Q = skew*p(:,1:3);
    q = skew*p(:,4);
    Q = Q(1:2,:);
    q = -q(1:2,:);
    QQ = blkdiag(QQ, Q);
    qq = [qq; q];
    theta = IDCT_continuous(sequence_length, time_instance(iCamera));
    theta = theta(1:K);
    Theta = [Theta; blkdiag(theta, theta, theta)];
end
beta = (QQ*Theta)\qq;
