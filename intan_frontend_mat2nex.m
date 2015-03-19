function intan_frontend_mat2nex(DATA,FS)
% frontend takes a data matrix and writes an appropriate nex file
%
%
%
%
%

[storefile,storepath]=uiputfile('*.nex','New filename');
[nsamples,ntrials,nchannels]=size(DATA);

% format the data for writing

disp('Reformatting data (this may take a minute)..');
store_datavec=zeros(nsamples*ntrials,nchannels,'double'); 

for i=1:nchannels
	tmp=DATA(:,:,i);
	store_datavec(:,i)=tmp(:);
end

trial_stamps=1:ntrials;
trial_stamps(2:end)=(trial_stamps(2:end)*FS)+1;

disp('Writing data...');
nexfile=nexCreateFileData(40e3);

for i=1:size(store_datavec,2)
	nexfile=nexAddContinuous(nexfile,1/FS,FS,store_datavec(:,i),...
		[ 'CH ' num2str(i) ]);
end

nexfile=nexAddEvent(nexfile,trial_stamps/FS,'trialtimes');
writeNexFile(nexfile,fullfile(storepath,storefile));

