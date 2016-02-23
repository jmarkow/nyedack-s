function nyedack_s_main(INCHANNELS,OUTPUT,varargin)
% CLI interface for recording data through the MATLAB session interface
%
%	nyedack_main(INCHANNELS,OUTPUT,varargin)
%
%	INCHANNELS
%	vector of NIDAQ channels to record from (start from 0)
%
%	OUTPUT
%	structure specifying how to deliver output (leave empty for no output)
%
%	the following may be specified as parameter/value pairs:
%
%		fs
%		data acquisition sampling rate (default: 40e3)
%
%		save_dir
%		base directory for data storage (default: 'nyedack')
%
%		note
%		string containing note to include in data storage log (default: empty)
%
%		save_freq
%		frequency for dumping data to disk from memory (in s, default: 60)
%
%		in_device
%		input device location (default: 'dev2')
%
%		in_device_type (default: 'nidaq')
%
%		out_device
%		output device location (default: 'dev2')
%
%		output_device_type
%		output device type (default: 'nidaq')
%
%		folder_format
%		datestr format for data storage folders (default: 'yyyy-mm-dd')
%
%		file_format
%		datestr format for data storage file timestamp (default: 'yymmdd_HHMMSS')
%
%		file_basename
%		base for data storage filename (default: 'data')
%
%		out_dir
%		data storage sub directory (default: 'mat')
%
%		channel_labels
%		labels for INCHANNELS (cell array, default: empty)
%
%	Example:
%
%	Record from 'nidaq' 'dev2' channels [0:5], and preview data
%
%	>>nyedack_s_main([0:5],[],'in_device_type','nidaq','in_device','dev2');
%
%

% collect the input variables and use defaults if necessary

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% PARAMETER COLLECTION %%%%%%%%%%%%%%%%%

if nargin<2 | isempty(OUTPUT), OUTPUT=[]; end
if nargin<1 | isempty(INCHANNELS), INCHANNELS=0; end

nparams=length(varargin);

save_dir='nyedack_data'; % base directory to save
fs=40e3; % sampling frequency (in Hz)
note=''; % note to save in log file
save_freq=60; % save frequency (in s)
in_device='dev2'; % location of input device
in_device_type='ni'; % input device type
out_device='dev2'; % location of output device
out_device_type='ni'; % output device type
folder_format=''; % date string format for folders
file_format='yymmdd_HHMMSS'; % date string format for files
out_dir=''; % save files to this sub directory
channel_labels={}; % labels for INCHANNELS
file_basename=''; % basename for save files
simple_logging=false;
pxi_fix=0;
loop='nidaq';
dirname='C:\Program Files\Microsoft SDKs\Kinect\v2.0_1409\inc\';
dirname2 = 'C:\Users\dattalab\Desktop\KinectCommonBridge-2.0\KCBv2Lib';

if mod(nparams,2)>0
	error('Parameters must be specified as parameter/value pairs!');
end

for i=1:2:nparams
	switch lower(varargin{i})
		case 'note'
			note=varargin{i+1};
		case 'save_dir'
			save_dir=varargin{i+1};
		case 'fs'
			fs=varargin{i+1};
		case 'save_freq'
			save_freq=varargin{i+1};
		case 'in_device_type'
			in_device_type=varargin{i+1};
		case 'in_device'
			in_device=varargin{i+1};
		case 'out_device_type'
			out_device_type=varargin{i+1};
		case 'out_device'
			out_device=varargin{i+1};
		case 'folder_format'
			folder_format=varargin{i+1};
		case 'out_dir'
			out_dir=varargin{i+1};
		case 'channel_labels'
			channel_labels=varargin{i+1};
		case 'file_basename'
			file_basename=varargin{i+1};
		case 'file_format'
			file_format=varargin{i+1};
		case 'pxi_fix'
			pxi_fix=varargin{i+1};
    case 'loop'
      loop=varargin{i+1};
		case 'simple_logging'
			simple_logging=varargin{i+1};
		otherwise
	end
end

if isempty(file_basename)
	file_basename=input('Enter base filename:  ','s');
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% TODO: put preview back in

% compute the save frequency in seconds

sprintf('Will save every %g minutes\n',save_freq/60);

% create the necessary directories for dumping the data

nchannels=length(INCHANNELS);
nlabels=length(channel_labels);

for i=nlabels+1:nchannels
	channel_labels{i}=sprintf('CH %i',INCHANNELS(i));
end

start_time=([datestr(now,'HHMMSS')]);

% open the analog input object

if strcmp(lower(loop),'nidaq+kinect') & simple_logging
	% include check for PCI device that can sample this first
	%save_freq=1/fs;
end

session=nyedack_s_init_input(INCHANNELS,...
	'pxi_fix',pxi_fix,...
	'in_device_type',in_device_type,...
	'in_device',in_device,...
	'fs',fs,...
	'channel_labels',channel_labels,...
	'save_freq',save_freq);

% set the parameters of the analog input object

save_dir=fullfile(save_dir,datestr(now,folder_format),out_dir);

if ~exist(save_dir,'dir')
	mkdir(save_dir);
end

logfile_name=sprintf('%s_%s',fullfile(save_dir,'log'),datestr(now,30));
logfile=fopen([ logfile_name '.txt' ],'w');

fprintf(logfile,'Run started at %s\n\n',datestr(now));
fprintf(logfile,[note '\n']);
fprintf(logfile,'User specified save frequency: %g minutes\n',save_freq/60);
fprintf(logfile,'Sampling rate:  %g\nChannels=[',fs);

for i=1:length(INCHANNELS)
	fprintf(logfile,' %g ',INCHANNELS(i));
end

fprintf(logfile,']\n\n');
kinect_filename=fullfile(save_dir,[ file_basename '_' datestr(now,file_format)]);
nidaq_fid=[];
reference_tic=[];

if (strcmp(lower(loop),'nidaq+kinect') | strcmp(lower(loop),'nidaq+kinect2')) & simple_logging

	% probably want to write out configuration...

	nidaq_fid=fopen([kinect_filename '_nidaq.bin'],'wb+');
	nidaq_log=fopen([kinect_filename '_nidaq.txt'],'w');

	nchannels=length(session.Channels);

	fprintf(nidaq_log,'Dtype: double\n');
	fprintf(nidaq_log,'%i rows\n',nchannels+1);
	fprintf(nidaq_log,'File format:\nTimestamps\n');

	for i=1:nchannels
		fprintf(nidaq_log,'CH %s\n',session.Channels(i).Name);
	end

	fclose(nidaq_log);

	listeners{1}=addlistener(session,'DataAvailable',...
			@(obj,event) nyedack_s_dump_data_simple(obj,event,nidaq_fid));

else

	listeners{1}=addlistener(session,'DataAvailable',...
		@(obj,event) nyedack_s_dump_data(obj,event,save_dir,file_basename,file_format,logfile));

end

objects{1}=session;

% TODO: add outputs here

% record until we reach the stopping time or the quit button is pressed
% rudimentary set of buttons to pause, resume or quit
% perhaps add a button for manual triggering of the output for testing

switch lower(loop)

	case 'nidaq'

		nyedack_s_loop_nidaq(session,objects,listeners,logfile);

	case 'nidaq+kinect'

		% get the kinect ready for prime time if we're using it

		[kinect_status,kinect_objects]=kinect_v1_init(varargin{:});

    if kinect_status~=0
      error('Could not initialize kinect.');
    end

		% filename should at least be in same directory

    kinect_objects=kinect_v1_logging(kinect_objects,varargin{:},...
			'filename',kinect_filename);
		nyedack_s_loop_nidaq_kinect(session,objects,listeners,logfile,...
			kinect_objects,nidaq_fid,varargin{:},'reference_tic',reference_tic);

	case 'nidaq+kinect2'

		% kinect 2, load libraries, initialize, start loop

		kinect_v2_load_libraries(dirname,dirname2);

		% initialize depth and color streams

		[kin_id,frame_ptr_color,frame_description_ptr_color,status]=kinect_v2_init_color;

		if status~=0
			error('Error initializing color string');
		end

		[kin_id,frame_ptr_depth,frame_description_ptr_depth,status]=kinect_v2_init_depth;

		if status~=0
			error('Error initializing depth stream');
		end

		nyedack_s_loop_nidaq_kinect_v2(session,objects,listeners,logfile,nidaq_fid,...
			kin_id,frame_ptr_color,frame_description_ptr_color,...
			frame_ptr_depth,frame_description_ptr_depth,kinect_filename,varargin{:});

	otherwise

	%TODO: kinect2, arduino

		error('Did not understand loop type');

end
