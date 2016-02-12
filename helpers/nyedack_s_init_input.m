function SESSION=nyedack_s_init_input(INCHANNELS,varargin)
%
%
%
%

nparams=length(varargin);

base_dir='nyedack_data'; % base directory to save
fs=40e3; % sampling frequency (in Hz)
note=''; % note to save in log file
save_freq=60; % save frequency (in s)
in_device='dev2'; % location of input device
in_device_type='ni'; % input device type
pxi_fix=0;
channels_labels={};

if mod(nparams,2)>0
	error('Parameters must be specified as parameter/value pairs!');
end

for i=1:2:nparams
	switch lower(varargin{i})
		case 'fs'
			fs=varargin{i+1};
		case 'save_freq'
			save_freq=varargin{i+1};
		case 'in_device_type'
			in_device_type=varargin{i+1};
		case 'in_device'
			in_device=varargin{i+1};
		case 'channel_labels'
			channel_labels=varargin{i+1};
		case 'file_basename'
			file_basename=varargin{i+1};
		case 'pxi_fix'
			pxi_fix=varargin{i+1};
		otherwise
	end
end

daq.reset;

if pxi_fix
	daq.HardwareInfo.getInstance('DisableReferenceClockSynchronization',true);
end

% TODO: break out setup into another function
% TODO: support for alternative data sources

SESSION=daq.createSession(in_device_type);
addAnalogInputChannel(SESSION,in_device,INCHANNELS,'voltage');
SESSION.Rate=fs;
SESSION.IsContinuous=1;

for i=1:length(SESSION.Channels)

	param_names=fieldnames(SESSION.Channels(i));

	if ~isempty(channel_labels)
		SESSION.Channels(i).Name=channel_labels{i};
	end
	
	SESSION.Channels(i).Coupling='DC';

	if any(strcmp(param_names,'TerminalConfig'))
		SESSION.Channels(i).TerminalConfig='SingleEnded';
	elseif any(strcmp(param_names,'InputType'))
		SESSION.Channels(i).InputType='SingleEnded';
	else
		error('Could not set NiDaq input type');
	end

end

% check to see if the actual sampling rate meets our specs, otherwise bail

actualrate=SESSION.Rate;
if actualrate ~= fs
	error(['Actual sampling rate (' num2str(actualrate) ') not equal to target (' num2str(fs) ')' ]);
end

SESSION.NotifyWhenDataAvailableExceeds=round(save_freq*actualrate);
