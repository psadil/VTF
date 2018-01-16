function correct = analyzeResp( response, answer )

correct = zeros([1,length(answer)]);
for a = 1:length(answer)
    switch answer{a}
        case response{a}
            correct(a) = 1;
        otherwise
            correct(a) = 0;
    end
    
end

end


