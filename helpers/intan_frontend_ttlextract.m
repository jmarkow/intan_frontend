function EXT_PTS=intan_frontend_ttlextract(BIRDSTRUCT,AUDIO_PAD,BIRD_SPLIT,DIR_STRUCT,DISP_BAND,COLORS,PROC_FILE,PROC_DIR)
%
%
%

detection=BIRDSTRUCT.ttl.data(:)>.5;
EXT_PTS=markolab_collate_idxs(detection,round(AUDIO_PAD*BIRDSTRUCT.ttl.fs))/BIRDSTRUCT.ttl.fs;

if ~isempty(EXT_PTS)

	disp('Found ttl..');

	intan_frontend_dataextract(BIRD_SPLIT,BIRDSTRUCT,DIR_STRUCT,...
			EXT_PTS,DISP_BAND(1),DISP_BAND(2),COLORS,'audio',1,'songdet1_','_ttl');

	% if we found TTL pulses and ttl_skip is on, skip song detection and move on to next file
end

