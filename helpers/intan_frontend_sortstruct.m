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

for k=1:length(map_types)

	curr_map=TOKENS.(map_types{k});
	src=curr_map.source;
	check_fields=fieldnames(BIRDSTRUCT.(src));

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

	if isfield(BIRDSTRUCT,curr_map.source) 

		BIRDSTRUCT.(map_types{k})=BIRDSTRUCT.(src);

		idx=[];
		for l=1:length(BIRDSTRUCT.(src).labels)
			idx(l)=any(BIRDSTRUCT.(src).labels(l)==curr_map.channels);
		end

		% if we have a port argument, use it

		if isfield(curr_map,'ports') & isfield(BIRDSTRUCT.(src),'ports')
			idx2=[];
			for l=1:length(BIRDSTRUCT.(src).ports)
				idx2(l)=any(BIRDSTRUCT.(src).ports(l)==curr_map.ports);
			end
			idx=(idx&idx2);
		end

		idx=find(idx);

		for l=1:length(check_fields)
			if isfield(BIRDSTRUCT.(src),check_fields{l})
				ndim=ndims(BIRDSTRUCT.(src).(check_fields{l}));
				if ndim==2
					BIRDSTRUCT.(map_types{k}).(check_fields{l})=BIRDSTRUCT.(src).(check_fields{l})(:,idx);
					if to_del
						BIRDSTRUCT.(src).(check_fields{l})(:,idx)=[];
					end
				elseif ndim==1
					BIRDSTRUCT.(map_types{k}).(check_fields{l})=BIRDSTRUCT.(src).(check_fields{l});
				end
			end
		end

		if isempty(BIRDSTRUCT.(src).data) & isfield(BIRDSTRUCT.(src),'t')
			BIRDSTRUCT.(src).t=[];
		end

	end
end

