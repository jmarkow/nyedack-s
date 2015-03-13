function dump_data(obj,event,save_dir,folder_format,out_dir,file_basename,file_format,logfile)

% basically, a circular buffer is used!

%disp('Dumping data...');

% if getdata trips up clear the buffer and keep going!

% do we want to preview?

actualrate=obj.Rate;
nchannels=length(obj.Channels);

%%% preview code

data.voltage=event.Data;
data.time=event.TimeStemps;

datafile_name=[ file_basename '_' datestr(now,file_format) '.mat' ];

data.fs=actualrate;
data.labels={};
data.names={};
data.parameters.sensor_range={};

for i=1:nchannels
	data.labels{i}=obj.Channel(i).ID;
	data.names{i}=obj.Channel(i).Name;
	data.parameters.sensor_range{i}=obj.Channel(i).Range;
end

if ~isempty(folder_format)	
	save_dir=fullfile(save_dir,datestr(now,folder_format),out_dir);
end

if ~exist(save_dir,'dir')
	mkdir(save_dir);
end

save(fullfile(save_dir,datafile_name),'data');
fprintf(logfile,'%s saved successfully at %s\n',fullfile(save_dir,datafile_name),datestr(now));
disp([ fullfile(save_dir,datafile_name) ' saved successfully at ' datestr(now) ]);
