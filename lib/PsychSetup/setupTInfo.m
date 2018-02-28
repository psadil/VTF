function tInfo = setupTInfo( expParams, stim, data, dimming_data, input, constants )
%setupDebug setup values specific to debug levels

% := number of flips in a trial * number of trials + (1 flip for each ITI)

switch input.responder
    
    case 'setup'
        nFlips_total = expParams.scan_time * (1 / stim.update_phase_sec);
        tInfo = table;
        tInfo.flip = (1:nFlips_total)' ;
        tInfo.vbl_expected_from0 = (0:stim.update_phase_sec:(expParams.scan_time-stim.update_phase_sec))';
        tInfo.trial = NaN(nFlips_total,1);
        tInfo.flipWithinTrial = NaN(nFlips_total,1);
        
        switch input.experiment
            case 'contrast'
                tInfo.contrast_left = zeros(nFlips_total,1);
                tInfo.contrast_right = zeros(nFlips_total,1);
                tInfo.orientation_left = zeros(nFlips_total,1);
                tInfo.orientation_right = zeros(nFlips_total,1);
                for trial = 1:expParams.nTrials
                    flipWithinTrial = 1;
                    for flip = 1:nFlips_total
                        if all(tInfo.vbl_expected_from0(flip) >= data.onset(data.trial==trial) ) && ...
                                ( any(tInfo.vbl_expected_from0(flip) < data.onset(data.trial==(trial+1)) ) || ...
                                trial == expParams.nTrials )
                            tInfo.trial(flip) = trial;
                            tInfo.flipWithinTrial(flip) = flipWithinTrial;
                            flipWithinTrial = flipWithinTrial + 1;
                        end
                        
                        if (tInfo.vbl_expected_from0(flip) >= data.onset(data.trial==trial .* strcmp(data.side, {'left'}))) && ...
                                (tInfo.vbl_expected_from0(flip) < data.tEnd_expected_from0(data.trial==(trial) .* strcmp(data.side, {'left'})) )
                            tInfo.contrast_left(flip) = data.contrast(data.trial==trial .* strcmp(data.side, {'left'}));
                            tInfo.orientation_left(flip) = data.orientation(data.trial==trial .* strcmp(data.side, {'left'}));
                        end
                        if (tInfo.vbl_expected_from0(flip) >= data.onset(data.trial==trial .* strcmp(data.side, {'right'}))) && ...
                                (tInfo.vbl_expected_from0(flip) < data.tEnd_expected_from0(data.trial==(trial) .* strcmp(data.side, {'right'})))
                            tInfo.contrast_right(flip) = data.contrast(data.trial==trial .* strcmp(data.side, {'right'}));
                            tInfo.orientation_right(flip) = data.orientation(data.trial==trial .* strcmp(data.side, {'right'}));
                        end
                    end
                end
                
            case 'localizer'
                tInfo.contrast_left = zeros(nFlips_total,1);
                tInfo.contrast_right = zeros(nFlips_total,1);
                for trial = 1:expParams.nTrials
                    flipWithinTrial = 1;
                    for flip = 1:nFlips_total
                        if tInfo.vbl_expected_from0(flip) >= data.onset(data.trial==trial) && ...
                                ( any(tInfo.vbl_expected_from0(flip) < data.onset(data.trial==(trial+1)) ) || ...
                                trial == expParams.nTrials )
                            tInfo.trial(flip) = trial;
                            tInfo.flipWithinTrial(flip) = flipWithinTrial;
                            flipWithinTrial = flipWithinTrial + 1;
                            
                            % to minimize the tunnel effect and intensity
                            % of the stimulus (for participant), only half
                            % of screen is active at once
                            switch data.trial_type{trial}
                                case 'checkerboard_left'
                                    tInfo.contrast_left(flip) = stim.contrast;
                                    tInfo.contrast_right(flip) = 0;
                                case 'checkerboard_right'
                                    tInfo.contrast_left(flip) = 0;
                                    tInfo.contrast_right(flip) = stim.contrast;
                            end
                            
                        end
%                         if (tInfo.vbl_expected_from0(flip) >= data.onset(data.trial==trial)) && ...
%                                 (tInfo.vbl_expected_from0(flip) < data.tEnd_expected_from0(data.trial==(trial)))
%                         end
                    end
                end
                tInfo.orientation_1 = repelem(stim.orientations_deg(1), nFlips_total)';
                tInfo.orientation_2 = repelem(stim.orientations_deg(2), nFlips_total)';
        end
        
        
        tInfo.dim = zeros(nFlips_total,1);
        tInfo.roboResponse_expected = repelem({[]}, nFlips_total)';
        tInfo.trial_dim = NaN([nFlips_total,1]);
        for flip = 1:nFlips_total
            for trial_dimming = 1:max(dimming_data.trial)
                if tInfo.vbl_expected_from0(flip) >= dimming_data.onset(dimming_data.trial == trial_dimming) && ...
                        any(tInfo.vbl_expected_from0(flip) < dimming_data.tEnd_expected_from0(dimming_data.trial == trial_dimming))
                    tInfo.trial_dim(flip) = trial_dimming;
                    tInfo.dim(flip) = 1;
                    tInfo.roboResponse_expected(flip) = dimming_data.roboResponse_expected(trial_dimming);
                end
            end
        end
        
        % for each flip, want to know when it flipped, when it should have flipped,
        % and whether it missed
        tInfo.vbl = NaN(nFlips_total, 1);
        tInfo.vbl_expected_fromTrigger = NaN(nFlips_total, 1);
        tInfo.missed = NaN(nFlips_total, 1);
        
        % On every trial's flip, one of the two gratings changes phase
        % NaN indicates neither is changing (happens on ITI flip and first flip per trial)
        tInfo.whichGratingToFlip =  repmat((1:2)', [nFlips_total/2, 1]);
        
        % each flip of the stimulus has a random new phase (repeats are allowed)
        tInfo.phase_orientation_left = ...
            reshape(randsample(linspace(0, 360 - (360/stim.n_phase_orientations), stim.n_phase_orientations), ...
            nFlips_total*stim.n_gratings_per_side/stim.reps_per_grating, true),...
            nFlips_total, stim.n_gratings_per_side/stim.reps_per_grating);
        tInfo.phase_orientation_right = ...
            reshape(randsample(linspace(0, 360 - (360/stim.n_phase_orientations), stim.n_phase_orientations), ...
            nFlips_total*stim.n_gratings_per_side/stim.reps_per_grating, true),...
            nFlips_total, stim.n_gratings_per_side/stim.reps_per_grating);
        
        % each grating should only change orientations on every other flip
        tInfo.phase_orientation_left(2:2:end) = ...
            tInfo.phase_orientation_left(1:2:end);
        tInfo.phase_orientation_right(3:2:end) = ...
            tInfo.phase_orientation_right(2:2:end-1);
        
        writetable(tInfo, constants.tInfo, 'Filetype', 'text', 'Delimiter', 'tab');
    otherwise
        
        tInfo = struct2table(tdfread(constants.tInfo, 'tab'));
        tInfo.roboResponse_expected = strtrim(cellstr(num2str(tInfo.roboResponse_expected)));
end

end
