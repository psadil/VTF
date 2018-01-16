function d = genDists()

minValue = 100;
maxValue = 10*100;
minDiff = 50;
maxDiff = 200;
N = 5;
d = zeros(N,1);
if any(diff(d) <= minDiff | diff(d) >= maxDiff | ...
        min(d) <= minValue+minDiff | max(d) <= maxValue - minDiff)
    d = sort(randperm(maxValue,N))';
end

end