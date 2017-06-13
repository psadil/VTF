function img = makeGrating(p, sf, ang, contrast)
% make an oriented gabor

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


end