function nyedack_s_loop_nidaq_kinect(SESSION,NIDAQ_OBJECTS,NIDAQ_LISTENERS,LOGFILE,KINECT_OBJECTS,varargin)
%
%
%
%

preview_mode=1;
reference_tic=[];
downsample_fact=2;
frame_skip=1;
status_check=0;
wait_time=5;
filename='';
file_format='yymmdd_HHMMSS'; % date string format for files

nparams=length(varargin);

if mod(nparams,2)>0
	error('Parameters must be specified as parameter/value pairs!');
end

for i=1:2:nparams
  switch lower(varargin{i})
    case 'preview_mode'
      preview_mode=varargin{i+1};
    case 'downsample_fact'
      downsample_fact=2;
    case 'frame_skip'
      frame_skip=1;
		case 'status_check'
			status_check=varargin{i+1};
		case 'wait_time'
			wait_time=varargin{i+1};
		case 'filename'
			filename=varargin{i+1};
		case 'file_format'
			file_format=varargin{i+1};
    otherwise
	end
end

% TODO: status updates for kinect and nidaq
% nidaq initialization

fprintf('Setting up NiDAQ interface...');

[button_figure.nidaq,components.nidaq]=nyedack_s_button_fig('fig_name','NyeDack Acquition');

% add figure for output as well

set(components.nidaq.stop_button,'call',...
	{@nyedack_s_stop_routine,...
	LOGFILE,NIDAQ_OBJECTS,components.nidaq.status_text,components.nidaq.start_button,components.nidaq.stop_button});
set(components.nidaq.start_button,'call',...
	{@nyedack_s_start_routine,...
	LOGFILE,NIDAQ_OBJECTS,components.nidaq.status_text,components.nidaq.start_button,components.nidaq.stop_button});

% refresh rate of scope determined by TimerPeriod

set(components.nidaq.quit_button,'call',...
	{@nyedack_s_early_quit,button_figure.nidaq});

warning('off','daq:general:nosave');

fprintf('done\n');

% kinect initialization

nframes=KINECT_OBJECTS.color_vid.TriggerRepeat;
nframes_per_trig=KINECT_OBJECTS.color_vid.FramesPerTrigger;

res=KINECT_OBJECTS.depth_vid.VideoResolution;
hres=res(1);
vres=res(2);

if preview_mode==2
  res=KINECT_OBJECTS.depth_vid.VideoResolution;
elseif preview_mode==1
  res=KINECT_OBJECTS.color_vid.VideoResolution;
end

if preview_mode>0
  hres=res(1);
  vres=res(2);
  preview_fig=figure();
  image_h=imagesc(zeros(vres/downsample_fact,hres/downsample_fact));
	if preview_mode==2
  	colormap(gray);
	end
  %colorbar();
  title_h=title('Frame data...');
else
  preview_fig=[];
end

% make an acquisition figure

fprintf('Setting up Kinect interface...');

[button_figure.kinect,components.kinect]=nyedack_s_button_fig('fig_name','Kinect Acquisition');

set(components.kinect.stop_button,'call',...
	{@kinect_v1_stop_routine,button_figure.kinect,...
  components.kinect.status_text,components.kinect.start_button,components.kinect.stop_button});
set(components.kinect.start_button,'call',...
	{@kinect_v1_start_routine,button_figure.kinect,...
  components.kinect.status_text,components.kinect.start_button,components.kinect.stop_button});
set(components.kinect.quit_button,'call',...
	{@nyedack_s_early_quit,button_figure.kinect});

pathname=get(KINECT_OBJECTS.depth_vid.DiskLogger,'Path');
filename=get(KINECT_OBJECTS.depth_vid.DiskLogger,'Filename');
[~,filename,~]=fileparts(filename);
csv_file=fopen(fullfile(pathname,[filename '.csv']),'w+');

set(button_figure.nidaq,'visible','on');
set(button_figure.kinect,'visible','on');
set(components.nidaq.status_text,'string','Status:  running','ForegroundColor','g');
set(components.kinect.status_text,'string','Status:  running','ForegroundColor','g');

cleanup_object=onCleanup(@()nyedack_s_cleanup_routine_kinect([],[],....
  LOGFILE,NIDAQ_OBJECTS,NIDAQ_LISTENERS,button_figure,...
	KINECT_OBJECTS,csv_file,preview_fig));

fprintf('done\n');

start([KINECT_OBJECTS.depth_vid KINECT_OBJECTS.color_vid]);
fprintf('Pausing for %i seconds before acquisition begins...',wait_time);
pause(wait_time); %allow time for both streams to start
fprintf('done\n');
% timing is relative to the first trigger, align to session start as best as possible

startBackground(SESSION);
reference_tic=tic;

trigger([KINECT_OBJECTS.color_vid KINECT_OBJECTS.depth_vid]);

% get difference in start times,  getdata returns abstime
% vid object.InitialTriggerTime
% stored in event.TriggerTime in session interface, USE IT
% etime(abstime,vid_object.InitialTriggerTime)=time
% so correct initial times, should remove bias

% Get the acquired frames and metadata.

[img_color, ts.color] = getdata(KINECT_OBJECTS.color_vid);
[img_depth, ts.depth] = getdata(KINECT_OBJECTS.depth_vid);

initial_trigger_time.color=KINECT_OBJECTS.color_vid.InitialTriggerTime;
initial_trigger_time.depth=KINECT_OBJECTS.depth_vid.InitialTriggerTime;

save(fullfile(pathname,[filename '_parameters.mat']),'initial_trigger_time');

fprintf(csv_file,'%s, %s\n','Color','Depth');
fprintf('Entering main acquisition loop...\n');

i=1;
while i<nframes

	if ~ishandle(button_figure.nidaq) | ~ishandle(button_figure.kinect)
		 break;
	end

	if mod(i,10)==0 && status_check
		nidaq_flag=1;
		for i=1:length(NIDAQ_OBJECTS)
			if ~NIDAQ_OBJECTS{i}.IsRunning
				nidaq_flag=0;
				break;
			end
		end

		if nidaq_flag
			set(components.nidaq.status_text,'string','Status:  running','ForegroundColor','g');
		else
			set(components.nidaq.status_text,'string','Status:  stopped','ForegroundColor','r');
		end

		color_status=strcmp(KINECT_OBJECTS.color_vid.Running,'on');
		depth_status=strcmp(KINECT_OBJECTS.depth_vid.Running,'on');

		if color_status & depth_status
			set(components.kinect.status_text,'string','Status:  running','ForegroundColor','g');
		else
			set(components.kinect.status_text,'string','Status:  stopped','ForegroundColor','r');
		end
	end

	% Trigger both color and depth sources.

	trigger([KINECT_OBJECTS.color_vid KINECT_OBJECTS.depth_vid]);

	% Get the acquired frames and metadata.

	[img_color, ts.color] = getdata(KINECT_OBJECTS.color_vid);
	[img_depth, ts.depth] = getdata(KINECT_OBJECTS.depth_vid);

	fprintf(csv_file,'%g, %g, %g\n',ts.color,ts.depth,toc(reference_tic));

	if preview_mode==2
		if mod(i,frame_skip) == 0
			set(image_h,'CData',img_depth(1:downsample_fact:end,1:downsample_fact:end));
		end
	elseif preview_mode==1
		if mod(i,frame_skip) == 0
			set(image_h,'CData',img_color(1:downsample_fact:end,1:downsample_fact:end,:));
		end
	end

	% write out data

	i=i+nframes_per_trig;
	%fwrite(parameters.depth_fid, swapbytes(int16(bitshift(img_depth,3))'), 'integer*2');

end
