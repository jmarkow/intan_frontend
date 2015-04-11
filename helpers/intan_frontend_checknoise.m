function [EMAIL_FLAG]=intan_frontend_readfile(DATA,FS,NOISECUT,NOISELEN,EMAIL_FLAG,EMAIL_MONITOR)
%
%
%
%

disp('Checking noise level');

nchannels=size(DATA,2);
[bnoise,anoise]=iirpeak(60/(FS/2),5/(FS/2));
noiseflag=zeros(1,nchannels);

for j=1:nchannels
	linenoise=filtfilt(bnoise,anoise,DATA(:,j));
	noiselevel=sqrt(mean(linenoise.^2));
	noisethresh=noiselevel>=NOISECUT;
	noiselen=sum(noisethresh)/FS;
	noiseflag(j)=noiselen>NOISELEN;
end

disp('Noise level flags:  ');

for j=1:nchannels
	fprintf(1,'%i',noiseflag(j));
end

fprintf(1,'\n');

% if all channels have high noise levels, alert the user

% TODO:  setting for checking across multiple files (could use simple counter)

if all(noiseflag) & EMAIL_FLAG==0 & EMAIL_MONITOR>0
	gmail_send(['Found excessive noise levels on all channels, make sure headstage is connected!']);
	EMAIL_FLAG=1; % don't send another e-mail!
end

