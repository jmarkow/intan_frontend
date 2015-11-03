function frontend_extract_data(FILENAME,DATA,DIRS,EXT_PTS,DISP_MINFS,DISP_MAXFS,COLORS,SOURCE,DATASAVE,PREFIX,SUFFIX,SKIP)
%extracts data given a set of points (e.g. TTL or SONG EXTRACTION)
%
%
%
%
%
%

row_size=10;
ttl_colors=[ 1 1 1;...
	1 0 1;...
	0 1 1;...
	0 0 1];

fs=DATA.(SOURCE).fs;

if nargin<12
	SKIP=0;
end

if nargin<11 
	SUFFIX='';
end

if nargin<10
	PREFIX='songdet1_';
end

if nargin<9 | isempty(DATASAVE)
	DATASAVE=0;
end

if nargin<8 | isempty(SOURCE)
	SOURCE='audio';
end

[b,a]=ellip(5,.2,40,[300/(fs/2)],'high'); 
if ~isfield(DATA.(SOURCE),'norm_data')
	DATA.(SOURCE).norm_data=filtfilt(b,a,DATA.(SOURCE).data);
end

[sonogram_im sonogram_f sonogram_t]=zftftb_pretty_sonogram(DATA.(SOURCE).norm_data,fs,'len',16.7,'overlap',3.3,'clipping',[-3 1]);

startidx=max([find(sonogram_f<=DISP_MINFS)]);

if isempty(startidx)
	startidx=1;
end

stopidx=min([find(sonogram_f>=DISP_MAXFS)]);

if isempty(stopidx)
	stopidx=length(sonogram_f);
end

sonogram_im=sonogram_im(startidx:stopidx,:)*62;
sonogram_im=flipdim(sonogram_im,1);
[f,t]=size(sonogram_im);
im_son_to_vec=(length(DATA.(SOURCE).norm_data)-(3.3/1e3)*fs)/t;

data_types={'ephys','ttl','digout','digin','adc','aux','audio','playback'};
found_types=fieldnames(DATA);

to_del=[];
for i=1:length(data_types)
	if ~any(strcmp(found_types,data_types{i}))
		to_del=[to_del i];
	end
end

data_types(to_del)=[];

savefun=@(filename,datastruct) save(filename,'-struct','datastruct','-v7.3');
sonogram_filename=fullfile(DIRS.image,[ PREFIX FILENAME SUFFIX '.gif' ]);

for i=1:size(EXT_PTS,1)


	% cut out the extraction

	EXTDATA=DATA;

	% trim all data types

	for j=1:length(data_types)

		% convert to samples (different possible fs for each data type)

		if ~isempty(EXTDATA.(data_types{j}).data)

			startpoint=floor(EXT_PTS(i,1)*EXTDATA.(data_types{j}).fs);
			endpoint=ceil(EXT_PTS(i,2)*EXTDATA.(data_types{j}).fs);

			%startpoint=EXT_PTS(i,1);
			%endpoint=EXT_PTS(i,2);

			if startpoint<1 & SKIP
				continue;
			elseif startpoint<1 & ~SKIP
				startpoint=1; 
			end

			if endpoint>length(EXTDATA.(data_types{j}).data) & SKIP
				continue;
			elseif endpoint>length(EXTDATA.(data_types{j}).data) & ~SKIP
				endpoint=length(EXTDATA.(data_types{j}).data);
			end

			EXTDATA.(data_types{j}).data=EXTDATA.(data_types{j}).data(startpoint:endpoint,:);

			if isfield(EXTDATA.(data_types{j}),'norm_data')
				EXTDATA.(data_types{j}).norm_data=EXTDATA.(data_types{j}).norm_data(startpoint:endpoint,:);
			end

			EXTDATA.(data_types{j}).t=EXTDATA.(data_types{j}).t(startpoint:endpoint);

		end
	end

	if length(EXTDATA.(SOURCE).norm_data)<2
		warning('Extraction failed, continuing...');
		continue;
	end

	save_name=[ PREFIX FILENAME '_chunk_' num2str(i) SUFFIX ];

	sonogram_im(1:10,ceil(startpoint/im_son_to_vec):ceil(endpoint/im_son_to_vec))=62;

	[chunk_sonogram_im chunk_sonogram_f chunk_sonogram_t]=zftftb_pretty_sonogram(EXTDATA.(SOURCE).norm_data,fs,'len',16.7,'overlap',10,'clipping',[-3 1]);

	startidx=max([find(chunk_sonogram_f<=DISP_MINFS)]);
	stopidx=min([find(chunk_sonogram_f>=DISP_MAXFS)]);

	chunk_sonogram_im=uint8(chunk_sonogram_im(startidx:stopidx,:)*62);
	chunk_sonogram_im=flipdim(chunk_sonogram_im,1);
	[f,t]=size(chunk_sonogram_im);
	chunk_im_son_to_vec=(length(EXTDATA.(SOURCE).data)-(10/1e3)*fs)/t;

	% convert sonogram to an rgb image, label TTL pulses using RGB stripes

	chunk_sonogram_im=ind2rgb(chunk_sonogram_im,colormap([ COLORS '(63)' ]));

	if isfield(EXTDATA,'ttl') & ~isempty(EXTDATA.ttl.data)

		[nsamples_ttl,nchannels_ttl]=size(EXTDATA.ttl.data);

		cur_top=1;

		nttl_colors=size(ttl_colors,1);

		for j=1:nchannels_ttl

			cur_row=cur_top:cur_top+(row_size-1);
			ttl_points=find(EXTDATA.ttl.data(:,j)>.5);

			ttl_son=round(ttl_points/chunk_im_son_to_vec);
			ttl_son(ttl_son<1|ttl_son>size(chunk_sonogram_im,2))=[];
			ttl_son=round(ttl_son);

			ttl_map=zeros(row_size,length(ttl_son),3);

			cur_color=reshape(ttl_colors(mod((j-1),nttl_colors)+1,:),[1 1 3]);
			chunk_sonogram_im(cur_row,ttl_son,:)=repmat(cur_color,[row_size length(ttl_son) 1]);
		
			cur_top=cur_top+row_size;

		end

	end

	[chunk_sonogram_im,new_map]=rgb2ind(chunk_sonogram_im,63);
	imwrite(chunk_sonogram_im,new_map,fullfile(DIRS.image,[ save_name '.gif']),'gif');

	% normalize audio to write out to wav file

	min_audio=min(EXTDATA.(SOURCE).norm_data(:));
	max_audio=max(EXTDATA.(SOURCE).norm_data(:));

	if min_audio + max_audio < 0
		EXTDATA.(SOURCE).norm_data=EXTDATA.(SOURCE).norm_data./(-min_audio);
	else
		EXTDATA.(SOURCE).norm_data=EXTDATA.(SOURCE).norm_data./(max_audio*(1+1e-3));
	end

	audiowrite(fullfile(DIRS.wav,[ save_name '.wav' ]),EXTDATA.(SOURCE).norm_data,round(fs));

	%wavwrite(EXTDATA.(SOURCE).norm_data,fs,fullfile(DIRS.wav,[ save_name '.wav']));

	% remove all data used for plotting (i.e. norm_data)

	for j=1:length(data_types)
		if isfield(EXTDATA.(data_types{j}),'norm_data')
			EXTDATA.(data_types{j})=rmfield(EXTDATA.(data_types{j}),'norm_data');
		end
	end

	%EXTDATA.(SOURCE)=rmfield(EXTDATA.(SOURCE),'norm_data');

	if DATASAVE
		savefun(fullfile(DIRS.data,[ save_name '.mat']),EXTDATA);
	end

	clear EXTDATA;
end

reformatted_im=markolab_im_reformat(sonogram_im,(ceil((length(DATA.(SOURCE).data)/fs)/10)));
imwrite(uint8(reformatted_im),colormap([ COLORS '(63)']),sonogram_filename,'gif');

