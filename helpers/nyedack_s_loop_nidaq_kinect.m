function nyedack_s_loop_nidaq_kinect(SESSION,NIDAQ_OBJECTS,NIDAQ_LISTENERS,LOGFILE,SAVE_DIR,KINECT_OBJECTS,varargin)
%
%
%
%

% nidaq initialization

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

% kinect initialization

start([KINECT_OBJECTS.depth_vid KINECT_OBJECTS.color_vid]);
pause(3); %allow time for both streams to start

trigger([KINECT_OBJECTS.depth_vid KINECT_OBJECTS.color_vid]);
fprintf('Waiting for video objects to start...\n');
pause(.2);

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
  colormap(gray);
  %colorbar();
  title_h=title('Frame data...');
else
  preview_fig=[];
end

% make an acquisition figure

[button_figure.kinect,components.kinect]=nyedack_s_button_fig('fig_name','Kinect Acquisition');

set(components.kinect.stop_button,'call',...
	{@kinect_v1_stop_routine,button_figure.kinect,...
  components.kinect.status_text,components.kinect.start_button,components.kinect.stop_button});
set(components.kinect.start_button,'call',...
	{@kinect_v1_start_routine,button_figure.kinect,...
  components.kinect.status_text,components.kinect.start_button,components.kinect.stop_button});
set(components.kinect.quit_button,'call',...
	{@nyedack_s_early_quit,button_figure.kinect});

parameters=KINECT_OBJECTS.depth_vid.UserData
[pathname,filename,ext]=fileparts(parameters.depth_filename);
csv_file=fopen(fullfile(pathname,[filename '.csv']),'w+');

set(button_figure.nidaq,'visible','on');
set(button_figure.kinect,'visible','on');

startBackground(SESSION);

set(components.nidaq.status_text,'string','Status:  running','ForegroundColor','g');
set(components.kinect.status_text,'string','Status:  running','ForegroundColor','g');

cleanup_object=onCleanup(@()nyedack_s_cleanup_routine_kinect([],[],....
  SAVE_DIR,LOGFILE,NIDAQ_OBJECTS,NIDAQ_LISTENERS,...
	KINECT_OBJECTS,[parameters.depth_fig csv_file],preview_fig));

% aggregate oncleanup

while i<nframes

	if ~ishandle(button_figure.nidaq) | ~ishandle(button_figure.kinect)
		 break;
	end

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

	% Trigger both color and depth sources.
  trigger([OBJECTS.color_vid OBJECTS.depth_vid]);

  % Get the acquired frames and metadata.
  [img_color, ts.color] = getdata(OBJECTS.color_vid);
  [img_depth, ts.depth] = getdata(OBJECTS.depth_vid);

  if preview_mode==2
    if mod(i,frame_skip) == 0
      set(image_h,'CData',img_depth(1:downsample_fact:end,1:downsample_fact:end));
    end
  elseif preview_mode==1
    if mod(i,frame_skip) == 0
      set(image_h,'CData',img_color(1:downsample_fact:end,1:downsample_fact:end));
    end
  end

  % write out data

  i=i+nframes_per_trig;
  fwrite(parameters.depth_fid, swapbytes(int16(bitshift(img_depth,3))'), 'integer*2');

  if ~isempty(reference_tic)
    % time elapsed since reference tic, use to align to other data
    fprintf(csv_file,'%g, %g, %g\n',ts.color,ts.depth,toc);
  else
    fprintf(csv_file,'%g, %g\n');
  end

	i=i+nframes_per_trig;

end
