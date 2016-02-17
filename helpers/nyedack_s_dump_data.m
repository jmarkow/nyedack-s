function dump_data(obj,event,save_dir,file_basename,file_format,logfile)
% TODO: create another version that simply dumps to a text file by appending
% with option to use toc timestamps (will be critical for syncing)
% basically, a circular buffer is used!

%disp('Dumping data...');

% if getdata trips up clear the buffer and keep going!

% do we want to preview?

actualrate=obj.Rate;
nchannels=length(obj.Channels);

%%% preview code

data.voltage=event.Data;
data.time=event.TimeStamps;
data.parameters.initial_trigger_time=event.TriggerTime;

datafile_name=[ file_basename '_' ...
       datestr(addtodate(now,-round(data.time(end)),'second'),file_format) '.mat' ];

data.fs=actualrate;
data.labels={};
data.names={};
data.parameters.sensor_range={};

for i=1:nchannels
	data.labels{i}=obj.Channels(i).ID;
	data.names{i}=obj.Channels(i).Name;
	data.parameters.sensor_range{i}=obj.Channels(i).Range;
end

if ~exist(save_dir,'dir')
	mkdir(save_dir);
end

save(fullfile(save_dir,datafile_name),'data');
fprintf(logfile,'%s saved successfully at %s\n',fullfile(save_dir,datafile_name),datestr(now));
disp([ fullfile(save_dir,datafile_name) ' saved successfully at ' datestr(now) ]);
