function [DATASTRUCT,EMAIL_FLAG]=intan_frontend_readfile(FILE,EMAIL_FLAG,EMAIL_MONITOR)
%
%
%
%

DATASTRUCT.filestatus=1;

try
	DATASTRUCT=intan_frontend_readdata(FILE);
	DATASTRUCT.original_filename=FILE;
catch err
	disp([err])
	disp('Could not read file, skipping...');
end


if DATASTRUCT.filestatus>0

	if EMAIL_FLAG==0 & EMAIL_MONITOR>0
		gmail_send(['File reading error, may need to restart the intan_frontend!']);
		EMAIL_FLAG=1; % don't send another e-mail!
	end

	fclose('all'); % read_intan does not properly close file if it bails

end
