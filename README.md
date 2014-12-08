# Welcome (i.e. what does this do?)

This package is designed to work with data generated the by the Intan RHA/RHD series acquisition boards in MATLAB. The typical usage scenario is to run this script in MATLAB as a daemon to process files generated by the RHA or RHD acquisition systems.  As files are generated, the software automatically extracts "relevant" data and discards "irrelevant" data.  In Tim Gardner's lab, we use the software to only extract electrophysiology recorded during zebra finch vocalizations.  Some other uses include extracting data aligned to stimulus playback.

The input is RHA/RHD acquisition board-generated data, and the output is automatically organized files read to be analyzed in MATLAB.  It should be noted that using this toolbox requires a passing familiarity with MATLAB, as it is command window oriented (i.e. no pretty GUI). 

===

# Table of Contents

1. [Requirements](#requirements)
2. [Data types](#data-types) 
3. [Directories](#quick-start)
4. [Conventions](#conventions)
5. [Data extraction](#template-alignment)
6. [Extracted data structure](@extracted-data-structure)
7. [Filename Options](#filename-options)
8. [Script Options](#script-options)


###Requirements

This has been tested using MATLAB 2010A and later on Windows and Mac (Linux should be fine).  The only Toolbox required is the Signal Processing toolbox. 

###Data types

So far the two data types that are guaranteed to work are files generated by the Intan RHA/RHD acquisition systems, which generated *.int and *.rnd files, respectively.  The software can be extended to work with other file types, and Open Ephys is already in the works.   

###Directories

First you need to create the following five directories:

```
/WHERE_I_STORE_DATA/staging/
/WHERE_I_STORE_DATA/staging/processed/
/WHERE_I_STORE_DATA/staging/unprocessed/
/WHERE_I_STORE_DATA/staging/unorganized/
/WHERE_I_STORE_DATA/intan_data/
```
Note that these can all be automatically generated using the script intan_frontend_mkdirs.m

| Directory | Notes |
|-----------|---------|
| staging | Contains all subdirectories used for processing "raw" Intan data |
| staging/processed/ | Contains raw data files already processed |
| staging/unprocessed/ | Data goes here to be processed |
| staging/unorganized/ | Data is dumped here if it can't be parsed|
| intan_data/ | Base directory for processed data | 

All of these directories can be customized (see [script options](#script-options)).

###Conventions

By default, the software will attempt to parse metadata about your recording from the **filename itself**.  This means that proper data extraction requires appropriate naming conventions.  The only two required specifications are the *ANIMAL ID* and *RECORDING ID*.  More precisely:

```
[ANIMALID]_[RECORDINGID]_[OPTION1]_[OPTION2]_[TIMESTAMP]
```

Underscore `_` is the default delimiter, but this can be changed in the [script options](#script-options). The timestamp is automatically appended by the Intan acquisition software, so you are only responsible for the other options.  An example base filename (i.e. without the timestamp) is:

```
lb119_LeftHVC_mic1adc_playback3adc
```

This means that the animal ID is lb119 the recording ID is LeftHVC and the final two options specify where task-relevant data can be found (more on these [here](#filename-options).  The extracted data will be placed in:

```
intan_data/lb119/LeftHVC/YYYY-MM-DD
```
Where YYYY-MM-DD is the datestamp for the data (e.g. 2014-02-13).

###Data Extraction

When "relevant" data is found, it is extracted into the /intan_data/ directory with the following structure by default:

```
/ANIMAL_ID/RECORDING_ID/YYYY-MM-DD
```

Sub-directories of this directory contain different data types:

| Sub-dir | Data type |
|---------|-----------|
| gif | Spectrograms of audio |
| mat | MATLAB files that containing all extracted data |
| wav | *.wav files of audio |

If the task is based on TTL signals or playback this will be appended to the basic sub-directory names for clarity, e.g. `gif_playback` would contain spectrograms of stimuli played to the animal, or `mat_ttl` would contain data aligned to TTL signals.

###Extracted Data Structure

Data contained in the `gif` and `wav` directories should be self-explanatory.  The MATLAB files in the `mat` directory contain the following variables:

| Variable | Data type | Description |
|----------|-----------|-------------|
| ttl | structure (fields: fs, data, time) | Contains TTL trace |
| ephys | structure (fields: fs, data, time, labels, ports) | Contains epyhys data |
| audio | structure (fields: fs, data, time) | Contains audio data |
| playback | structure (fields: fs, data, time) | Contains playback data |
| file_datenum | MATLAB date number | File first write datestamp |


###Filename Options

Many relevant options can be specified in the base filename itself.  If they are not specified, they can be passed using the script option `parse_options` (see [script options](#script-options) for more details). Recall the format:

```
[ANIMALID]_[RECORDINGID]_[OPTION1]_[OPTION2]_[OPTIONX]
```

These options can be broken down into specifying the data *type*, *source* (RHD only), *channel*, and *port* (RHD only).  The data type can be:

| Type | Notes |
|----------|-------|
| mic | Audio source |
| ttl | TTL source |
| playback | playback source |

This is followed by the *channel* then the *source*.  The data source can be (relevant only for RHD system):

| Source | Text | Notes |
|--------|------|-------|
| ADC | c | Acquisition board ADC |
| Digital input | digin | Acquisition board digital input |
| Digital output | digout | Acquisition board digital output |
| AUX | a | Headstage auxiliary input |

So to indicate that you're recording audio data on ADC-0 and playback data on ADC-1 with animal LDR4 with recording ID NCM:

```
LD4_NCM_mic0adc_playback1adc
```

By default, audio and playback data will be saved in the MATLAB files, while spectrograms and wav files will only contain the audio data from ADC-0 (the script can generate spectrograms and wav files for the playback data by specifying [script options](#script-options).  

Also, multiple animals can be specified using the `bird_delimiter` (see [script options](#script-options).  For instance:

```
LD4_NCM_mic0adc_playback1adc&rm7_HVC_mic2adc_ttl4digin
```

This base filename would specify that animal ID 1 is LD4 recording ID 2 is NCM, animal ID 2 is rm7 and recording ID 2 is HVC.  The various options specify where audio, playback, or TTL signals reside.

###Script Options

There are lots and lots of options to specify how things run "under-the-hood", e.g. the spectrogram parameters, sensitivity of vocalization detection, what directories to use, etc.  All options are specified using parameter/value pairs (examples are given below the table).  Here's the full list, organized thematically:

| Parameter | Description | Default |
|-----------|-------------|---------|
| `song_band` | Lower and upper edge of song detection band | `[2e3 6e3]` |
| `window` | Song detection fft window (samples) | `250` |
| `noverlap` | Song detection fft overlap (samples) | `0` |
| `ratio_thresh` | Song detection in:out power ratio threshold | `2` |
| `pow_thresh` | Song detection power threshold | `.3` |
| `songduration` | Song detection smoothing parameter (seconds) | `.8` | 
| `song_thresh` | Song detection final threshold | `.2` |
| `folder_format` | Extracted data folder format (MATLAB datestring format) | `yyyy-mm-dd` | 
| `delimiter` | Delimiter used to parse filename options | `_`|
| `bird_delimiter` | Delimiter used to parse different animals | `&` |
| `auto_delete_int` | Number of days to wait before automatically deleting processed "raw" data | `inf` |
| `disp_band` | Spectrogram display frequency band | `[1 10e3]` |
| `filtering` | High-pass audio signal for display and song detection (corner freq. in Hz, leave empty to turn this feature off) | `300` |
| `audio_pad` | Amount of data to extract before and after song detection (seconds) | `7` |
| `ttl_extract` | Extract data segments based on TTL high | `0` |
| `ttl_skip` | Skip song and playback detection if TTL high | `0` |
| `playback_extract` | Extract data segments based on playback | `0` |
| `playback_skip` | Skip song detection if playback detected | `0` |
| `playback_rmswin` | Computed RMS using specified window (seconds) | `.025` |
| `playback_thresh` | Playback RMS detection threshold | `.01` |
| `sleep_window` | Time window to separately collect sleep data (24 hr format) | `[22 7]` |
| `birdid` | Manually specify the animal ID (if empty auto-detect) | |
| `recid` | Manually specify the recording ID (if empty auto-detect) | |
| `parse_options` | Specify additional parse options using the [file options](#file-options) syntax (use delimiter for multiple options) | |
| `sleep_fileinterval` | How often to start saving sleep data (minutes) | `10` |
| `sleep_segment` | How much data to keep per file interval (seconds) | `5` |
| `email_monitor` | E-mail user if file hasn't been created in *N* minutes (0 turns this feature off) | `0` |
| `email_noisecut` | E-mail user if 60 Hz power exceeds this threshold (0 turns this feature off) | `0` |
| `email_noiselen` | E-mail user of 60 Hz noise threshold exceeded for *N* seconds | `0` |













