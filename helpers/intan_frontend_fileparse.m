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

if length(filesplit)>2
	for i=1:length(token.names)
	
		idx=max(find(~cellfun(@isempty,strfind(filesplit(3:end),...
			token.parse_strings{i}))));

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

% third should be mic trace

foundtokens=fieldnames(token.result);

for i=1:length(foundtokens)

	string=filesplit{token.result.(foundtokens{i})};
	[channel,~,endpoint]=regexpi(string,'\d+','match');

	fprintf('%s:\t',foundtokens{i});

	if ~isempty(channel)
		PARSED.(foundtokens{i}).trace=str2num(channel{1});
		fprintf('channel %i\t',PARSED.(foundtokens{i}).trace);
	end

	if length(string)>endpoint
		tmp=string(endpoint+1:end);
		if strcmp(lower(tmp(1)),'m')
			tmp_source='main';
		elseif strcmp(lower(tmp(1:2)),'au')
			tmp_source='aux';
		elseif strcmp(lower(tmp(1:2)),'ad')
			tmp_source='adc';
		else
			warning('Did not understand %s source setting %s',foundtokens{i},tmp);
			tmp_source='main';
		end
	else
		warning('Did not understand %s source setting',foundtokens{i});
		tmp_source='main';
	end

	PARSED.(foundtokens{i}).source=tmp_source;
	fprintf('source %s\t',PARSED.(foundtokens{i}).source);


	[port,~,endpoint]=regexpi(string,'port','match');

	if ~isempty(port) & length(string)>endpoint
		tmp=lower(string(endpoint+1:end));
		PARSED.(foundtokens{i}).port=tmp(1);
		fprintf('port %s\t',PARSED.(foundtokens{i}).port);
	end

	fprintf('\n');

end


if isfield(PARSED,'port')

	tmp=filesplit{PARSED.data_port.port};
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

