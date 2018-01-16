function img = makeGrating(p, sf, ang, contrast, expt)
% make an oriented gabor

switch expt
    case 'contrast'
        phase = rand*pi;
        
        % first make the grating
        ramp = p.x.*sin(ang)+p.y.*cos(ang);
        img = sign(cos(2*pi*ramp*sf+phase));
        img = round(((contrast*img)+1)*127)+1;
        
        % mask out the outer region to make it a circle
        id  = p.x.^2 + p.y.^2 >= 1.^2;
        img(id) = 128;
        
        % mask out an inner circle around fixation as well
        id  = p.x.^2 + p.y.^2 <= p.innerR;
        img(id) = 128;
        
        % pass the image through the look up table to correct gamma vals
        img = p.LUT(img);
        
        
    case 'localizer'
        %make matrices x and y with meshgrid to hold pixel locations in terms
        %of visual angle.
        tmpX  = linspace(-p.stimSizePix,p.stimSizePix,p.stimSizePix*2);
        [x, y] = meshgrid(tmpX);
        
        %make a checkerboard image containing -1's and 1's.
        chex = sign(sin(2*pi*p.sf*x).*sin(2*pi*p.sf*y));
        circle = x.^2+y.^2<=(p.stimSizePix)^2;
        id  = x.^2 + y.^2 <= p.innerRPix^2;
        
        % first make the standard checkerboards
        img1 = chex.*circle;
        img2 = -1*img1; % contrast reversal
        
        img1(id) = 0;
        img2(id) = 0;
        
        
end

end