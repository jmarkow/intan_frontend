function [PARSED PORTS DATENUM]=frontend_fileparse(FILENAME,DELIM,DATEFMT)
%frontend_fileparse
%
%	frontend_fileparse(FILENAME,DELIM,FMT)
%
%	FILENAME
%
%	DELIM
%
%	FMT
%
% TODO: update handling of multiple data entries

if nargin<3 | isempty(DATEFMT), DATEFMT='yymmddHHMMSS'; end
if nargin<2 | isempty(DELIM), DELIM='\_'; end
if nargin<1 | isempty(FILENAME), error('Need filename to continue!'); end

DATENUM=[];
PORTS='';
PARSED=[];

port_labels='abcd';

[path,filename,ext]=fileparts(FILENAME);
filesplit=regexpi(filename,DELIM,'split');

token.names={'mic','ttl','data_port','playback','data'};
token.parse_strings={'mic','ttl','^port[a-z]\+','playback','data'};
alias.name1={'mic'};
alias.name2={'audio'};

if length(filesplit)>2
	for i=1:length(token.names)
	
		idx=find(~cellfun(@isempty,strfind(filesplit(3:end),...
			token.parse_strings{i})));

		if ~isempty(idx)
			fprintf(1,'Found %s token at position %i\n',token.names{i},idx+2);
			token.result.(token.names{i})=idx+2;
		end

	end

end

% these are hardcoded, first is always bird id, second is recording id

PARSED.birdid=filesplit{1};
PARSED.recid=filesplit{2};

fprintf('Bird ID:\t%s\nRecording ID:\t%s\n',PARSED.birdid,PARSED.recid)

% datetoken is the last two

datetoken=length(filesplit);
datetoken=[datetoken-1:datetoken];
 
fprintf('Assuming date tokens in positions %i and %i\n',datetoken(1),datetoken(2));

% third should be mic channel

foundtokens=fieldnames(token.result);

% remap any names that act as aliases (mic=audio, e.g.)

for i=1:length(alias.name1)
	if isfield(token.result,alias.name1{i})
		token.result.(alias.name2{i})=token.result.(alias.name1{i});
		token.result=rmfield(token.result,alias.name1{i});
	end
end

foundtokens=fieldnames(token.result);

for i=1:length(foundtokens)

	idx=token.result.(foundtokens{i});
	original_name=foundtokens{i};

	for j=1:length(idx)
		string=lower(filesplit{idx(j)});

		suffix='';
		counter=1;


		while isfield(PARSED,foundtokens{i})
			suffix=counter;
			foundtokens{i}=sprintf('%s%i',original_name,counter);
			counter=counter+1;
		end

		% first search for range, if we find it, extract and remove from string

		channels=[];
		[range_hit,startpoint,endpoint]=regexpi(string,'\d+-\d+','match');

		if ~isempty(range_hit)
			idxs=regexpi(range_hit,'\d+','match');

			for k=1:length(idxs)
				if length(idxs{k})==2
					tmp=str2num(idxs{k}{1}):str2num(idxs{k}{2});
					channels=[channels tmp];
				end
			end	
		end

		% strip out the ranges

		while ~isempty(regexpi(string,'\d+-\d+','match'))
			[~,startpoint,endpoint]=regexpi(string,'\d+-\d+','match');
			string(startpoint(1):endpoint(1))=[];
		end

		% if there's anything left, add it

		[new_channels,~,endpoint]=regexpi(string,'\d+','match');

		for k=1:length(new_channels)
			channels=[channels str2num(new_channels{k})];
		end

		% remove duplicates

		channels=unique(channels);

		% if we found multiple channels

		fprintf('%s:\t',foundtokens{i});
		if ~isempty(channels)
			fprintf('\n\tchannel ');
			for k=1:length(channels)
				PARSED.(foundtokens{i}).channels(k)=channels(k);
				fprintf(' %i',PARSED.(foundtokens{i}).channels(k));
			end
		end

		if ~isempty(strfind(string,'ma'))|~isempty(strfind(string,'ep'))
			tmp_source='ephys';
		elseif ~isempty(strfind(string,'au'))
			tmp_source='aux';
		elseif ~isempty(strfind(string,'ad'))
			tmp_source='adc';
		else
			warning('Did not understand %s source setting %s',foundtokens{i},string);
			tmp_source='ephys';
		end

		PARSED.(foundtokens{i}).source=tmp_source;
		fprintf('\n\tsource %s\t',PARSED.(foundtokens{i}).source);

		[port,~,endpoint]=regexpi(string,'port','match');

		if ~isempty(port) & length(string)>endpoint
			tmp=lower(string(endpoint+1:end));
			PARSED.(foundtokens{i}).ports=tmp(1);
			fprintf('\n\tport %s\t',PARSED.(foundtokens{i}).ports);
		end

		fprintf('\n');
	end

end


if isfield(PARSED,'data_port') & isfield(PARSED.data_port,'ports')

	tmp=filesplit{PARSED.data_port.ports};
	[port,startpoint,endpoint]=regexpi(tmp,'port','match');
	tmp=lower(tmp(endpoint+1:end));

	for i=1:length(port_labels)
		if ~isempty(strfind(tmp,port_labels(i)))
			PORTS=[ PORTS port_labels(i) ];
		end
	end
else

	% if isempty assume all ports

	PORTS=port_labels;

end	


if ~isempty(datetoken)
	DATENUM=datenum([filesplit{datetoken}],'yymmddHHMMSS');
	fprintf('File date:\t%s\n',datestr(DATENUM));
end

