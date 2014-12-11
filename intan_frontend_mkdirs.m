function intan_frontend_mkdirs()
%intan_frontend_mkdirs.m creates the directory structure for the ephys pipeline:
%
%pwd/staging/processed
%pwd/staging/unprocessed
%pwd/data/intan_data
%
%the Intan files should be stored in pwd/staging/unprocessed

staging=fullfile(pwd,'staging');

mkdir(fullfile(staging,'unprocessed'));
mkdir(fullfile(staging,'processed'));
mkdir('intan_data');
