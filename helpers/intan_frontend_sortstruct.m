function BIRDSTRUCT=intan_frontend_sortstruct(TOKENS,BIRDSTRUCT)
%
%
%

skip_fields={'t','fs'};
map_types=fieldnames(TOKENS);
map_types(strcmp(map_types,'birdid'))=[];
map_types(strcmp(map_types,'recid'))=[];

% make sure data is last

tmp=strcmp(map_types,'data');	

if any(tmp)
	map_types(tmp)=[];
	map_types{end+1}='data';
end

for i=1:length(map_types)

	curr_map=TOKENS.(map_types{i});
	src=curr_map.source;
	check_fields=fieldnames(BIRDSTRUCT.(src));

	for j=1:length(skip_fields)
		check_fields(strcmp(lower(check_fields),skip_fields{j}))=[];
	end

	to_del=1;

	% special data type maps src to itself, only keeping user specified channels

	if strcmp(map_types{i},'data')
		map_types{i}=src;
		to_del=0;
	end

	% map the data if the source exists

	if isfield(BIRDSTRUCT,curr_map.source) 

		BIRDSTRUCT.(map_types{i})=BIRDSTRUCT.(src);

		% if there is a channel map use it, otherwise copy all channels

		if isfield(curr_map,'channels')
			idx=[];
			for j=1:length(BIRDSTRUCT.(src).labels)
				idx(j)=any(BIRDSTRUCT.(src).labels(j)==curr_map.channels);
			end
		else
			idx=ones(size(BIRDSTRUCT.(src).labels);
		end

		% if we have a port argument, use it as well

		if isfield(curr_map,'ports') & isfield(BIRDSTRUCT.(src),'ports')
			idx2=[];
			for j=1:length(BIRDSTRUCT.(src).ports)
				idx2(j)=any(BIRDSTRUCT.(src).ports(j)==curr_map.ports);
			end
			idx=(idx&idx2);
		end

		idx=find(idx);

		for j=1:length(check_fields)
			if isfield(BIRDSTRUCT.(src),check_fields{j})
				ndim=ndims(BIRDSTRUCT.(src).(check_fields{j}));
				if ndim==2
					BIRDSTRUCT.(map_types{i}).(check_fields{j})=BIRDSTRUCT.(src).(check_fields{j})(:,idx);
					if to_del
						BIRDSTRUCT.(src).(check_fields{j})(:,idx)=[];
					end
				elseif ndim==1
					BIRDSTRUCT.(map_types{i}).(check_fields{j})=BIRDSTRUCT.(src).(check_fields{j});
				end
			end
		end

		if isempty(BIRDSTRUCT.(src).data) & isfield(BIRDSTRUCT.(src),'t')
			BIRDSTRUCT.(src).t=[];
		end

	end
end

