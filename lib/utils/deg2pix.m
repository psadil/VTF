function pixels = deg2pix(size_cm, size_pix, view_distance_cm, desired_degrees )

% pixels = tan(deg2rad(desired_degrees/2)) * 2 * view_distance_mm * ...
%     (size_pix / size_mm);

max_degrees = rad2deg(2 * atan( size_cm / view_distance_cm ));
pixels_per_degree = size_pix / max_degrees;
pixels = pixels_per_degree * desired_degrees;

end