function intan_frontend_songdaemon(DIR,varargin)
%runs Intan song detection indefinitely
%
%	intan_frontend_songdaemon(DIR,options);
%
%	DIR
%	directory that contains files for processing
%	
%	options
%	parameter/value pairs (see the help from intan_frontend_main.m for all options
%
%
%Before running, make sure you have created the appropriate directory structure
%using ephys_pipeline_mkdirs.m.  Also, be sure to use the following file naming
%convention:
%
%BIRDID_RECORDINGID_[option1]_[options2]_intantimestamps
%
%e.g. lpur35_hvc_mic12adc_playback2digin_[timestamp]
%
%the Intan demo software automatically appends a timestamp.  Run the daemon
%in the "unprocessed" directory, where the Intan files should be saved.  As they
%are processed, they will be moved to the "processed" directory. See the help
%for intan_frontend_main.m for more detailed options.
%
%see also intan_frontend_mkdirs.m,intan_frontend_main.m
%

% simply loops intan_songdet_intmic in the current directory

if nargin<1
	DIR=pwd;
end

email_flag=0; % did we send an e-mail? initialize as 0
last_file=clock; % when was the last file processed?
interval=120;

while 1==1
	
	% return the email flag in case we're monitoring so multiple emails are not sent

	[email_flag,last_file]=intan_frontend_main(DIR,varargin{:},'email_flag',email_flag,'last_file',last_file);
	disp(['Email flag:  ' num2str(email_flag)]);
	pause(interval);
end
