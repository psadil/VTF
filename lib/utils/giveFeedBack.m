function [  ] = giveFeedBack( correct, fb )


switch correct
    case 1
        noise = fb.cor;
    case 0
        noise = fb.incor;
end

sound(noise, fb.sr)


end

