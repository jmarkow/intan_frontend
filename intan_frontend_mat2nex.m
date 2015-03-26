function intan_frontend_mat2nex(EPHYS_DATA,EPHYS_FS,AUDIO_DATA,AUDIO_FS)
% frontend takes a data matrix and writes an appropriate nex file
%
%
%
%
%

[storefile,storepath]=uiputfile('*.nex','New filename');
[nsamples,ntrials,nchannels]=size(EPHYS_DATA);

% format the data for writing

disp('Reformatting data (this may take a minute)..');
store_datavec=zeros(nsamples*ntrials,nchannels,'double'); 

for i=1:nchannels
	tmp=EPHYS_DATA(:,:,i);
	store_datavec(:,i)=tmp(:);
end

trial_stamps=1:ntrials;
trial_stamps(2:end)=(trial_stamps(2:end)*nsamples)+1;

disp('Writing data...');
nexfile=nexCreateFileData(40e3);

for i=1:size(store_datavec,2)
	nexfile=nexAddContinuous(nexfile,1/EPHYS_FS,EPHYS_FS,store_datavec(:,i),...
		[ 'CH ' num2str(i) ]);
end

store_audio=AUDIO_DATA(:);

nexfile=nexAddContinuous(nexfile,1/AUDIO_FS,AUDIO_FS,store_audio,[ 'Microphone' ]);
nexfile=nexAddEvent(nexfile,trial_stamps/EPHYS_FS,'trialtimes');

writeNexFile(nexfile,fullfile(storepath,storefile));
