function [EMAIL_FLAG,LAST_FILE]=intan_frontend_main(DIR,varargin)
%intan_frontend_main.m is the core script for processing Intan files
%on the fly.  Its primary task is to determine which bits of data
%to keep and which to throw-away.  This has been designed from the ground
%up to work with RHA/RHD-series Intan recordings aligned to vocalizations,
%but can easily be configured to work with other types of trial data.  
%
%	intan_frontend_main(DIR,varargin)
%
%	DIR
%	directory to process 
%
%	the following may be specified as parameter/value pairs
%
%
%		ratio_thresh
%		ratio between song frequencies and non-song frequencies for song detection (default: 4)
%
%		window
%		spectrogram window for song detection (default: 250 samples)
%		
%		noverlap
%		window overlap for song detection (default: 0)
%
%		song_thresh
%		song threshold (default: .2)
%	
%		songduration
%		song duration for song detection in secs (default: .8 seconds)
%
%		low
%		parameter for spectrogram display (default: 5), lower if spectrogram are dim		
%
%		high
%		parameter for spectrogram display (default: 10)
%
%		colors
%		spectrogram colormap (default: hot)		
%
%		filtering
%		high pass corner for mic trace (default: 300 Hz)
%
%		audio_pad
%		extra data to left and right of extraction points to extract (default: .2 secs)
%
%		folder_format
%		folder format (date string) (default: yyyy-mm-dd)
%
%		image_pre
%		image sub directory (default: 'gif')
%	
%		wav_pre
%		wav sub directory (default: 'wav')
%
%		data_pre
%		data sub directory (default: 'mat')
%	
%		delimiter
%		delimiter for filename parsing (default: '\_', or underscore)
%
%
%
% see also zftftb_song_det.m, im_reformat.m
%
%
% To run this in daemon mode, intan_frontend_daemon.m in the directory with unprocessed Intan
% files.  Be sure to create the appropriate directory structure using epys_pipeline_mkdirs.m first.

% while running the daemon this can be changed 

song_ratio=2; % power ratio between song and non-song band
song_len=.005; % window to calculate ratio in (ms)
song_overlap=0; % just do no overlap, faster
song_thresh=.25; % between .2 and .3 seems to work best (higher is more exlusive)
song_band=[2e3 6e3];
song_pow=-inf; % raw power threshold (so extremely weak signals are excluded)
song_duration=.8; % moving average of ratio
clipping=-3;
colors='hot';
disp_band=[1 10e3];
filtering=300; % changed to 100 from 700 as a more sensible default, leave empty to filter later
audio_pad=7; % pad on either side of the extraction (in seconds)

% parameters for folder creation

folder_format='yyyy-mm-dd';
parse_string='auto'; % how to parse filenames, b=tokens.birdid, i=tokens.recid, m=micid, t=ttlid, d=date
		       % character position indicates which token (after delim split) contains the info

date_string='yymmddHHMMSS'; % parse date using datestr format
auto_delete_int=inf; % delete data n days old (set to inf to never delete)

% directory names

image_pre='gif';
wav_pre='wav';
data_pre='mat';
sleep_pre='sleep';

delimiter='_'; % delimiter for splitting fields in filename
bird_delimiter='\&'; % delimiter for splitting multiple birds

% sleep parameters

sleep_window=[ 22 7 ]; % times for keeping track of sleep data (24 hr time, start and stop)
sleep_fileinterval=10; % specify file interval (in minutes) 
sleep_segment=5; % how much data to keep (in seconds)

% email_parameters

email_monitor=0; % monitor file creation, email if no files created in email_monitor minutes
email_flag=0;
email_noisecut=0;
email_noiselen=4;
file_elapsed=0;

% ttl & playback parameters

ttl_extract=1; % set to 1 if you'd like to extract based on TTL
ttl_skip=0; % skip song detection if TTL detected?

playback_extract=0; % set to 1 if you'd like to extract based on playback
playback_thresh=.01;
playback_rmswin=.025;
playback_skip=0;

% define for manual parsing

ports='';
tokens.birdid='';
tokens.recid='';
parse_options='';
last_file=clock;
skip_fields={'t','fs'};

% TODO: option for custom e-mail function (just map to anonymous function)

file_check=5; % how long to wait between file reads to check if file is no longer being written (in seconds)

mfile_path = mfilename('fullpath');
[script_path,~,~]=fileparts(mfile_path);

% where to place the parsed files

root_dir=fullfile(pwd,'..','..','intan_data'); % where will the detected files go
proc_dir=fullfile(pwd,'..','processed'); % where do we put the files after processing, maybe auto-delete
					 % after we're confident in the operation of the pipeline
unorganized_dir=fullfile(pwd,'..','unorganized');

% internal parameters

data_types={'ttl','playback','audio'};

hline=repmat('#',[1 80]);

if ~exist(root_dir,'dir')
	mkdir(root_dir);
end

if ~exist(proc_dir,'dir')
	mkdir(proc_dir);
end

% directory for files that have not been recognized

if ~exist(unorganized_dir,'dir');
	mkdir(unorganized_dir);
end

% we should write out a log file with filtering parameters, when we started, whether song was
% detected in certain files, etc.

nparams=length(varargin);

if mod(nparams,2)>0
	error('Parameters must be specified as parameter/value pairs!');
end

for i=1:2:nparams
	switch lower(varargin{i})
		case 'ports'
			ports=varargin{i+1};
		case 'parse_options'
			parse_options=varargin{i+1};
		case 'last_file'
			last_file=varargin{i+1};
		case 'auto_delete_int'
			auto_delete_int=varargin{i+1};
		case 'sleep_window'
			sleep_window=varargin{i+1};
		case 'sleep_fileinterval'
			sleep_fileinterval=varargin{i+1};
		case 'sleep_segment'
			sleep_segment=varargin{i+1};
		case 'filtering'
			filtering=varargin{i+1};
		case 'audio_pad'
			audio_pad=varargin{i+1};
		case 'disp_band'
			disp_band=varargin{i+1};
		case 'song_thresh'
			song_thresh=varargin{i+1};
		case 'song_ratio'
			song_ratio=varargin{i+1};
		case 'song_duration'
			song_duration=varargin{i+1};
		case 'song_pow'
			song_pow=varargin{i+1};
		case 'song_len'
			song_len=varargin{i+1};
		case 'colors'
			colors=varargin{i+1};
		case 'folder_format'
			folder_format=varargin{i+1};
		case 'delimiter'
			delimiter=varargin{i+1};
		case 'ttl_skip'
			ttl_skip=varargin{i+1};
		case 'ttl_extract'
			ttl_extract=varargin{i+1};
		case 'email_monitor'
			email_monitor=varargin{i+1};
		case 'email_flag'
			email_flag=varargin{i+1};
		case 'playback_extract'
			playback_extract=varargin{i+1};
		case 'playback_thresh'
			playback_thresh=varargin{i+1};
		case 'playback_rmswin'
			playback_rmswin=varargin{i+1};
		case 'playback_skip'
			playback_skip=varargin{i+1};
		case 'birdid'
			birdid=varargin{i+1};
		case 'recid'
			recid=varargin{i+1};
		case 'root_dir'
			root_dir=varargin{i+1};
	end
end


% TODO: make data sorting more compact, map data sources and types automatically w/ fieldnames


if ~isempty(parse_options)

	if parse_options(1)~=delimiter
		parse_options=[delimiter parse_options ];
	end

	%if parse_options(end)~=delimiter
	%	parse_options=[parse_options delimiter];
    	%end

end

if exist('gmail_send')~=2
	disp('Email from MATLAB not figured, turning off auto-email features...');
	email_monitor=0;
end

EMAIL_FLAG=email_flag;
LAST_FILE=last_file;

if nargin<1
	DIR=pwd;
end

% read in int or rhd files

filelisting=dir(fullfile(DIR));

% delete directories

isdir=cat(1,filelisting(:).isdir);
filelisting(isdir)=[];

% read in appropriate suffixes 

filenames={filelisting(:).name};
hits=regexp(filenames,'\.(rhd|int|mat)','match');
hits=cellfun(@length,hits)>0;

filenames(~hits)=[];

proc_files={};
for i=1:length(filenames)
	proc_files{i}=fullfile(DIR,filenames{i});
end

clear filenames;

% check all files in proc directory and delete anything older than 
% auto-delete days

if ~isempty(auto_delete_int)
	intan_frontend_auto_delete(proc_dir,auto_delete_int,'rhd');
	intan_frontend_auto_delete(proc_dir,auto_delete_int,'int'); 
	intan_frontend_auto_delete(proc_dir,auto_delete_int,'mat'); 
end

tmp_filelisting=dir(fullfile(DIR));
tmp_filenames={tmp_filelisting(:).name};
tmp_hits=regexp(tmp_filenames,'\.(rhd|int|mat)','match');
tmp_hits=cellfun(@length,tmp_hits)>0;
tmp_filelisting=tmp_filelisting(tmp_hits);
tmp_datenums=cat(1,tmp_filelisting(:).datenum);

if email_monitor>0 & EMAIL_FLAG==0

	if ~isempty(tmp_datenums)
		LAST_FILE=datevec(max(tmp_datenums));
	end

	file_elapsed=etime(clock,LAST_FILE)/60; % time between now and when the last file was created
	disp(['Time since last file created (mins):  ' num2str(file_elapsed)]);

end

if email_monitor>0 & EMAIL_FLAG==0
	if file_elapsed>email_monitor
		gmail_send(['An Intan file has not been created in ' num2str(file_elapsed) ' minutes.']);
		EMAIL_FLAG=1; % don't send another e-mail!
	end
end

user_birdid=tokens.birdid;
user_recid=tokens.recid;

for i=1:length(proc_files)


	fclose('all'); % seems to be necessary

	% read in the data

	% parse for the bird name,zone and date
	% new folder format, yyyy-mm-dd for easy sorting (on Unix systems at least)	

	disp([repmat(hline,[2 1])]);
	disp(['Processing: ' proc_files{i}]);

	% try reading the file, if we fail, skip

	%%% check if file is still being written to, check byte change within N msec
	% when was the last file created

	dir1=dir(proc_files{i});
	pause(file_check);
	dir2=dir(proc_files{i});

	try
		bytedif=dir1.bytes-dir2.bytes;
	catch
		pause(10);
		bytedif=dir1.bytes-dir2.bytes;
	end

	% if we haven't written any new data in the past (file_check) seconds, assume
	% file has been written

	if bytedif==0
		[datastruct,EMAIL_FLAG]=intan_frontend_readfile(proc_files{i},EMAIL_FLAG,email_monitor);
	else
		disp('File still being written, continuing...');
		continue;
	end

	if datastruct.filestatus>0 
		disp('Could not read file, skipping...');
		pause();
		movefile(proc_files{i},proc_dir);
		continue;
	end

	% if we've defined a noise cutoff, use this to determine if the headstage is connected

	nchannels=size(datastruct.ephys.data,2);

	if email_noisecut>0 & nchannels>0 & isfield(datastruct,'ephys')
		EMAIL_FLAG=intan_frontend_checknoise(datastruct.ephys.data,datastruct.ephys.fs,email_noisecut,email_noiselen,EMAIL_FLAG,email_monitor);
	end

	% if we're successful reading, then move the file to a processed directory

	[path,name,ext]=fileparts(proc_files{i});

	% if user passes multiple birds, they are split by bird_delimiter, parsing is done
	% independently for each bird

	bird_split=regexp(name,bird_delimiter,'split');
	tokens=regexp(bird_split{end},delimiter,'split');

	nbirds=length(bird_split);
	last_bird=tokens{1};

	for j=2:length(tokens)-2
		last_bird=[ last_bird delimiter tokens{j} ];
	end

	bird_split{nbirds}=last_bird;

	% get the date tokens from the last bird, append to all others

	datetokens=[length(tokens)-1 length(tokens)];
	datestring='';

	for j=1:length(datetokens)
		datestring=[ datestring delimiter(end) tokens{datetokens(j)} ];
	end

	found_ports=unique(datastruct.ephys.ports); % which ports are currently being used?
	disp(['Found ports:  ' found_ports]);

	% form a data map

	for j=1:nbirds

		sleep_flag=0;

		% parse the file using the format string, insert parse options for manual option setting

		bird_split{j}=[bird_split{j} parse_options datestring];

		% auto_parse

		[tokens,ports,file_datenum]=...
			intan_frontend_fileparse(bird_split{j},delimiter,date_string);

		if ~isempty(user_birdid)
			tokens.birdid=user_birdid;
		end

		if ~isempty(user_recid)
			tokens.recid=user_recid;
		end

		disp(['Processing bird ' num2str(j) ' of ' num2str(nbirds) ]);
		disp(['File status:  ' num2str(datastruct.filestatus)]);

		% now create the folder it doesn't exist already

		foldername=fullfile(root_dir,tokens.birdid,tokens.recid,datestr(file_datenum,folder_format));	

		% create the bird directory

		if ~exist(fullfile(root_dir,tokens.birdid),'dir')
			mkdir(fullfile(root_dir,tokens.birdid));
		end

		% create the template directory and a little readme

		if ~exist(fullfile(root_dir,tokens.birdid,'templates'),'dir')
			mkdir(fullfile(root_dir,tokens.birdid,'templates'));
			copyfile(fullfile(script_path,'template_readme.txt'),...
				fullfile(root_dir,tokens.birdid,'templates','README.txt'));
		end

		if ~isempty(ports)

			include_ports=[];

			for k=1:length(ports)

				if any(ismember(lower(found_ports(:)),lower(ports(k))))
					include_ports=[include_ports ports(k)];
				end
			end
		else
			include_ports=found_ports;
		end

		include_ports=upper(include_ports);

		disp(['Will extract from ports: ' include_ports]);

		% loop through variables, anything with a port only take the include port

		datastruct.file_datenum=file_datenum;
		birdstruct=datastruct;

		data_types=fieldnames(birdstruct);

		for k=1:length(data_types)

			if isfield(birdstruct.(data_types{k}),'ports')

				idx=[];
				for l=1:length(include_ports)
					idx=[ idx find(birdstruct.(data_types{k}).ports==include_ports(l)) ];
				end	

				if isfield(birdstruct.(data_types{k}),'labels')
					birdstruct.(data_types{k}).labels=birdstruct.(data_types{k}).labels(idx);
				end

				if isfield(birdstruct.(data_types{k}),'data')
					birdstruct.(data_types{k}).data=birdstruct.(data_types{k}).data(:,idx);
				end

				birdstruct.(data_types{k}).ports=birdstruct.(data_types{k}).ports(idx);

			end

		end

		if ~exist(foldername,'dir')
			mkdir(foldername);
		end

		% standard song detection

		isaudio=isfield(tokens,'audio');
		isttl=isfield(tokens,'ttl');
		isplayback=isfield(tokens,'playback');
		isdata=isfield(tokens,'data');

		disp(['Flags: audio ' num2str(isaudio) ' ttl ' num2str(isttl) ' playback ' num2str(isplayback)]);

		map_types=fieldnames(tokens);
		map_types(strcmp(map_types,'birdid'))=[];
		map_types(strcmp(map_types,'recid'))=[];

		% map the data

		for k=1:length(map_types)

			curr_map=tokens.(map_types{k});
			src=curr_map.source;
			check_fields=fieldnames(birdstruct.(src));

			for l=1:length(skip_fields)
				check_fields(strcmp(lower(check_fields),skip_fields{l}))=[];
			end

			to_del=1;

			% special data type maps src to itself, only keeping user specified channels

			if strcmp(map_types{k},'data')
				map_types{k}=src;
				to_del=0;
			end

			% map the data if the source exists

			if isfield(birdstruct,curr_map.source) 

				birdstruct.(map_types{k})=birdstruct.(src);

				idx=[];
				for l=1:length(birdstruct.(src).labels)
					idx(l)=any(birdstruct.(src).labels(l)==curr_map.channels);
				end

				if isfield(curr_map,'ports') & isfield(birdstruct.(src),'ports')
					idx2=[];
					for l=1:length(birdstruct.(src).ports)
						idx2(l)=any(birdstruct.(src).ports(l)==curr_map.ports);
					end
					idx=(idx&idx2);
				end

				idx=find(idx);

				for l=1:length(check_fields)
					if isfield(birdstruct.(src),check_fields{l})
						ndim=ndims(birdstruct.(src).(check_fields{l}));
						if ndim==2
							birdstruct.(map_types{k}).(check_fields{l})=birdstruct.(src).(check_fields{l})(:,idx);
							if to_del
								birdstruct.(src).(check_fields{l})(:,idx)=[];
							end
						elseif ndim==1
							birdstruct.(map_types{k}).(check_fields{l})=birdstruct.(src).(check_fields{l});
						end
					end
				end

				if isempty(birdstruct.(src).data) & isfield(birdstruct.(src),'t')
					birdstruct.(src).t=[];
				end

			end
		end

		if ~isempty(file_datenum) & length(sleep_window)==2

			% convert the sleep window times to datenum

			[~,~,~,hour]=datevec(file_datenum);

			% compare hour, are we in the window?

			if hour>=sleep_window(1) | hour<=sleep_window(2)

				disp(['Processing sleep data for file ' proc_files{i}]);

				intan_frontend_sleepdata(birdstruct,bird_split{j},sleep_window,sleep_segment,sleep_fileinterval,sleep_pre,...
					fullfile(root_dir,tokens.birdid,tokens.recid),folder_format,delimiter);	

				sleep_flag=1;

				% TODO: skip song detection?

			end
		end

		intan_frontend_extract_mkdirs(foldername,image_pre,wav_pre,data_pre,isttl,isplayback);

		% set up file directories

		image_dir=fullfile(foldername,image_pre);
		wav_dir=fullfile(foldername,wav_pre);
		data_dir=fullfile(foldername,data_pre);

		image_dir_ttl=fullfile(foldername,[image_pre '_ttl']);
		wav_dir_ttl=fullfile(foldername,[wav_pre '_ttl']);
		data_dir_ttl=fullfile(foldername,[data_pre '_ttl']);

		image_dir_pback=fullfile(foldername,[image_pre '_pback']);
		wav_dir_pback=fullfile(foldername,[wav_pre '_pback']);
		data_dir_pback=fullfile(foldername,[data_pre '_pback']);

		if ~isaudio & ~isttl & ~sleep_flag & ~isplayback
			save(fullfile(data_dir,['songdet1_' bird_split{j} '.mat']),'-struct','birdstruct','-v7.3');
			clearvars birdstruct;
			continue;
		end

		% if we have a TTL trace, extract using the TTL

		dirstructttl=struct('image',image_dir_ttl,'wav',wav_dir_ttl,'data',data_dir_ttl);
		dirstructpback=struct('image',image_dir_pback,'wav',wav_dir_pback,'data',data_dir_pback);
		dirstruct=struct('image',image_dir,'wav',wav_dir,'data',data_dir);

		% first check TTL, sometimes we want to bail after TTL (ttl_skip)
		% second check playback, sometimes we want to bail after TTL/playback (min. amplitude threshold)
		% finally check for song

		ext_pts=[];

		if isttl & ttl_extract

			ext_pts=intan_frontend_ttlextract(birdstruct,audio_pad,bird_split{j},dirstructttl,...
				disp_band,colors,proc_files{i},proc_dir);

			if ~isempty(ext_pts) & ttl_skip

				disp('Skipping song detection...');

				try
					movefile(proc_files{i},proc_dir);
				catch
					disp(['Could not move file ' proc_files{i}]);
					fclose('all');
					continue;
				end

				continue;
			end	

		end

		% did we detect playback?

		if isplayback & playback_extract

			% insert song detection code, change audio to playback?, or pass flag for show 
			% playback data

			disp('Entering playback detection...');
			ext_pts=intan_frontend_ttlextract(birdstruct,filtering,rms_win,playback_thresh,audio_pad,...
				bird_split{j},dirstructplayback,disp_band,colors,proc_files{i},proc_dir);

			if ~isempty(ext_pts) & playback_skip
				try
					movefile(proc_files{i},proc_dir);
				catch
					disp(['Could not move file ' proc_files{i}]);
					fclose('all');
					continue;
				end

				disp('Skipping song detection...');
				continue;

			end

		end

		% did we detect song?

		if isaudio

			disp('Entering song detection...');

			if ~isempty(filtering)
				[b,a]=butter(5,[filtering/(birdstruct.audio.fs/2)],'high'); 
				birdstruct.audio.norm_data=filtfilt(b,a,birdstruct.audio.data);
			else
				birdstruct.audio.norm_data=detrend(birdstruct.audio.data);
			end

			birdstruct.audio.norm_data=birdstruct.audio.norm_data./max(abs(birdstruct.audio.norm_data));

			[song_bin,song_t]=zftftb_song_det(birdstruct.audio.norm_data,birdstruct.audio.fs,'song_band',song_band,...
				'len',song_len,'overlap',song_overlap,'song_duration',song_duration,...
				'ratio_thresh',song_ratio,'song_thresh',song_thresh,'pow_thresh',song_pow);

			raw_t=[1:length(birdstruct.audio.norm_data)]./birdstruct.audio.fs;

			% interpolate song detection to original space, collate idxs

			detection=interp1(song_t,double(song_bin),raw_t,'nearest'); 
			ext_pts=markolab_collate_idxs(detection,round(audio_pad*birdstruct.audio.fs))/birdstruct.audio.fs;

			if ~isempty(ext_pts)
				disp(['Song detected in file:  ' proc_files{i}]);
				intan_frontend_dataextract(bird_split{j},birdstruct,dirstruct,...
					ext_pts,disp_band(1),disp_band(2),colors,'audio',1,'songdet1_','');	
			end

		end

		% clear the datastructure for this bird

		clear birdstruct;


	end

	% if there is neither a mic nor a TTL signal, store everything?

	clearvars datastruct dirstruct dirstructttl;

	try
		movefile(proc_files{i},proc_dir);
	catch
		disp(['Could not move file ' proc_files{i}]);
		fclose('all');
		continue;
	end

end
