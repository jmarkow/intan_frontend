function EXT_PTS=intan_frontend_playbackextract(BIRDSTRUCT,FILTERING,WIN,THRESH,AUDIO_PAD,BIRD_SPLIT,DIR_STRUCT,DISP_BAND,COLORS,PROC_FILE,PROC_DIR)
%
%
%

% simply take rms of playback signal

if ~isempty(FILTERING)
	[b,a]=butter(5,[FILTERING/(BIRDSTRUCT.playback.fs/2)],'high'); 
	BIRDSTRUCT.playback.norm_data=filtfilt(b,a,BIRDSTRUCT.playback.data);
else
	BIRDSTRUCT.playback.norm_data=detrend(BIRDSTRUCT.playback.data);
end

BIRDSTRUCT.playback.norm_data=BIRDSTRUCT.playback.norm_data./max(abs(BIRDSTRUCT.playback.norm_data));

rmswin_smps=round(WIN*BIRDSTRUCT.playback.fs);
rms=sqrt(smooth(BIRDSTRUCT.playback.norm_data.^2,rmswin_smps));

detection=rms>THRESH;
EXT_PTS=markolab_collate_idxs(detection,round(audio_pad*BIRDSTRUCT.playback.fs))/BIRDSTRUCT.playback.fs;

if ~isempty(EXT_PTS)

	disp('Found playback...');

	intan_frontend_dataextract(BIRD_SPLIT,BIRDSTRUCT,DIR_STRUCT,...
		EXT_PTS,DISP_BAND(1),DISP_BAND(2),COLORS,'playback',1,'songdet1_','_pback');

end
