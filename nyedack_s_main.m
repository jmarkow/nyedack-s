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
%		base_dir
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

base_dir='nyedack_data'; % base directory to save
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
file_basename='data'; % basename for save files
pxi_fix=0;
loop='nidaq';

if mod(nparams,2)>0
	error('Parameters must be specified as parameter/value pairs!');
end

for i=1:2:nparams
	switch lower(varargin{i})
		case 'note'
			note=varargin{i+1};
		case 'base_dir'
			base_dir=varargin{i+1};
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
		otherwise
	end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% TODO: finish save_directory creation
% TODO: put preview back in
% TODO: change function names as appropriate
% TODO: simplify as much as possible!

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

session=nyedack_s_init_input(INCHANNELS,...
	'pxi_fix',pxi_fix,...
	'in_device_type',in_device_type,...
	'in_device',in_device,...
	'fs',fs,...
	'channel_labels',channel_labels,...
	'save_freq',save_freq)

% set the parameters of the analog input object

save_dir=fullfile(base_dir,datestr(now,folder_format),out_dir);

if ~exist(base_dir,'dir')
	mkdir(base_dir);
end

logfile_name=sprintf('%s_%s',fullfile(base_dir,'log'),datestr(now,30));
logfile=fopen([ logfile_name '.txt' ],'w');
fprintf(logfile,'Run started at %s\n\n',datestr(now));
fprintf(logfile,[note '\n']);
fprintf(logfile,'User specified save frequency: %g minutes\n',save_freq/60);
fprintf(logfile,'Sampling rate:  %g\nChannels=[',fs);

for i=1:length(INCHANNELS)
	fprintf(logfile,' %g ',INCHANNELS(i));
end

fprintf(logfile,']\n\n');

objects{1}=session;
listeners{1}=addlistener(session,'DataAvailable',...
	@(obj,event) nyedack_s_dump_data(obj,event,save_dir,folder_format,out_dir,file_basename,file_format,logfile));

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
			'filename',fullfile(base_dir,['video_data_' datestr(now,file_format)]));
		nyedack_s_loop_nidaq_kinect(session,objects,listeners,logfile,...
			kinect_objects,varargin{:})

	otherwise

		error('Did not understand loop type');

end
