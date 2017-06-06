function  img = makeGrating(p, sf, ang, contrast, phase)
% make an oriented gabor, e.g.
% p.n = 256;          %pixels
% [p.x,p.y] = meshgrid(linspace(-1,1,p.n));
% sf = 8;           %cycles/image
% p.ang = pi;         %radians (0 is right, pi/2 is up)
% p.sig = .33;        %1/e half width of gaussian
% p.c = 1;            % contrast (0-1)
%

    % first make the grating
    ramp = p.x.*sin(ang)+p.y.*cos(ang);
%     if phase==1
%         img = sign(cos(2*pi*ramp*sf));
%     else
        img = sign(cos(2*pi*ramp*sf+phase));        
%     end
    % then window with a bivariate gaussian
%     gauss = exp( - (p.x.^2 + p.y.^2)/p.sig^2);
%     img = img.*gauss;
    % scale by the contrast - assumes that on a scale of 0-255 black to
    % white
    img = round(((contrast*img)+1)*127)+1;
        
    % mask out the outer region to make it a circle
    id  = p.x.^2 + p.y.^2 >= 1.^2;
    img(id) = 128;
    
    % mask out an inner circle around fixation as well
    id  = p.x.^2 + p.y.^2 <= p.innerR;
    img(id) = 128;

    % pass the image through the look up table to correct gamma vals
    img = p.LUT(img);
    % colormap(gray);