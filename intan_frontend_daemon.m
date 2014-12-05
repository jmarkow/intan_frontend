function intan_frontend_songdaemon(DIR,varargin)
%runs Intan song detection indefinitely
%
%	ephys_songdaemon(DIR);
%
%	DIR
%	directory that contains files for processing
%
%
%Before running, make sure you have created the appropriate directory structure
%using ephys_pipeline_mkdirs.m.  Also, be sure to use the following file naming
%convention:
%
%BIRDID_RECORDINGID_mic#
%
%e.g. lpur35_hvc_mic12
%
%the Intan demo software automatically appends a timestamp.  Run the daemon
%in the "unprocessed" directory, where the Intan files should be saved.  As they
%are processed, they will be moved to the "processed" directory (NOTE:  FILES
%ARE NOT AUTOMATICALLY DELETED UNLESS SPECIFIED, THIS IS CONSIDERED A FEATURE 
%AND NOT A BUG AT THE MOMENT).  Song detections will be sorted by date, bird,
%and recording ID and placed in the "intan_data" folder. For detailed processing 
%options be sure to check intan_songdet_intmic.m
%
%see also intan_frontend_mkdirs.m,intan_frontend_main.m
%

%
%
%

% simply loops intan_songdet_intmic in the current directory

if nargin<1
	DIR=pwd;
end

email_flag=0;
last_file=clock;

while 1==1
	
	% return the email flag in case we're monitoring so multiple emails are not sent

	[email_flag,last_file]=intan_frontend_main(DIR,varargin{:},'email_flag',email_flag,'last_file',last_file);
	disp(['Email flag:  ' num2str(email_flag)]);
	pause(10);
end