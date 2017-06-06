function  img = makeGratingTrain(p, contrast,  phase, dir)
    % first make the grating
    p.ramp = p.x.*sin(dir)+p.y.*cos(dir);
    img = sign(cos(2*pi*p.ramp*p.sf+(pi*phase)));        
%     img = img .* p.gauss;
    img = round(((contrast*img)+1)*127)+1;

    % pass the image through the look up table to correct gamma vals
    id  = (p.x-p.xc).^2 + (p.y-p.yc).^2 <= p.r.^2;
    img(id) = 128;
    id  = (p.x-p.xc).^2 + (p.y-p.yc).^2 > 1.^2;
    img(id) = 128;
    img = p.LUT(img);