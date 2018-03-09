%{
contrast:

current preference is to call ga_contrast4. This is the simplest of the
algorithms. It doesn't bother optimizing order, which is super tricky and
maybe not really possible with so many stimulus conditions. Instead, just
the onsets are optimized.

localizer:
simple block design, not bothering to optimize anything

%}


ga_contrast4('participants', 5, 'runs', 0:10, 'task', 'contrast',...
    'n_orientation',12, 'n_contrast', 2, 'n_reps',2, 'scan_time', 420, ...
    'max_iti_flip', 37, 'epoch_length_max_flip', 50, 'algorithm','shuffle');

ga_contrast4('participants', 5, 'runs', 0:4, 'task', 'localizer',...
    'n_orientation', 2, 'n_contrast', 1, 'n_reps', 10, 'scan_time', 320, ...
    'max_iti_flip', 0, 'epoch_length_max_flip', 160, 'algorithm', 'block');
