function correct = analyzeResp( response, answer, keys )


if answer < 0 % contrast decrement
    if KbName(response) == find(keys.resp,1,'first')
        correct = 1;
    else
        correct = 0;
    end
else  % contrast increment
    if KbName(response) == find(keys.resp,1,'last')
        correct = 1;
    else
        correct = 0;
    end
end

end

