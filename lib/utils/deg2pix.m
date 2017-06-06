function pixels = deg2pix(deg, window)

pixelsPerDegree = window.width / ...
    (2 * (atand(window.screenWidthCM / (2*window.vDistCM))));

pixels = deg * pixelsPerDegree;

end