function EXT_PTS=intan_frontend_ttlextract(BIRDSTRUCT,AUDIO_PAD,BIRD_SPLIT,DIR_STRUCT,DISP_BAND,COLORS,PROC_FILE,PROC_DIR)
%
%
%

% ttl extraction is currently slaved to the first TTL channel, easy to modify for multiple...

nchannels=size(BIRDSTRUCT.ttl.data,2);

for i=1:nchannels

	detection=BIRDSTRUCT.ttl.data(:,i)>.5;
	EXT_PTS=markolab_collate_idxs(detection,round(AUDIO_PAD*BIRDSTRUCT.ttl.fs))/BIRDSTRUCT.ttl.fs;

	dir_types=fieldnames(DIR_STRUCT);
	NEW_STRUCT=DIR_STRUCT;

	if i>1
		for j=1:length(dir_types)
			NEW_STRUCT.(dir_types{j})=sprintf('%s%i',NEW_STRUCT.(dir_types{j}),i-1);
		end
	end

	if ~isempty(EXT_PTS)

		disp(['Found ttl in channel ' num2str(i) '...']);

		intan_frontend_dataextract(BIRD_SPLIT,BIRDSTRUCT,NEW_STRUCT,...
		EXT_PTS,DISP_BAND(1),DISP_BAND(2),COLORS,'audio',1,'songdet1_','_ttl');

		% if we found TTL pulses and ttl_skip is on, skip song detection and move on to next file

	end
	
end
