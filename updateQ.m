function [ qp ] = updateQ( correct, tType, qp )


% adjust the offsets if a training session
%             if ~p.fMRI
qp.conq(tType) = ...
    QuestUpdate(qp.conq(tType), log10(qp.cdThresh(tType)), correct);

%QuestQuantile suggestion for next contrast
qp.cdThresh(tType) = 10.^QuestQuantile(qp.conq(tType));

if qp.cdThresh(tType) > qp.max_con
    qp.cdThresh(tType) = qp.max_con;
elseif qp.cdThresh(tType) < qp.min_con
    qp.cdThresh(tType) = qp.min_con;
end


end

