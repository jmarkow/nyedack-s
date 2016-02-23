function nyedack_s_loop_nidaq_kinect_v2(...
	SESSION,NIDAQ_OBJECTS,NIDAQ_LISTENERS,LOGFILE,NIDAQ_FID,...
	KINECT_ID,FRAME_PTR_COLOR,FRAME_DESCRIPTION_PTR_COLOR,...
		FRAME_PTR_DEPTH,FRAME_DESCRIPTION_PTR_DEPTH,FILENAME,varargin)

%
%
%
%

preview_mode=1;
downsample_fact=2;
frame_skip=5;
status_check=0;
filename='';
rec_color=0;
color_bands=2; % which rgb band to record
color_downsample_fact=2;
nframes=inf;

nparams=length(varargin);

if mod(nparams,2)>0
	error('Parameters must be specified as parameter/value pairs!');
end

for i=1:2:nparams
  switch lower(varargin{i})
    case 'preview_mode'
      preview_mode=varargin{i+1};
    case 'downsample_fact'
      downsample_fact=varargin{i+1};
    case 'frame_skip'
      frame_skip=varargin{i+1};
		case 'status_check'
			status_check=varargin{i+1};
		case 'filename'
			filename=varargin{i+1};
      case 'simple_logging'
          simple_logging=varargin{i+1};
      case 'rec_color'
          rec_color=varargin{i+1};
      case 'color_downsample_fact'
          color_downsample_fact=varargin{i+1};
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

[pathname,filename,~]=fileparts(FILENAME);

csv_file=fopen(fullfile(pathname,[filename '.csv']),'wt');
depth_file=fopen(fullfile(pathname,[filename '_depth.bin']),'Wb');

if rec_color
	color_file=fopen(fullfile(pathname,[filename '_color.bin']),'Wb');
else
	color_file=[];
end

[arch,maxsize,endian]=computer;

metadata_file=fopen(fullfile(pathname,[filename '_parameters.txt']),'wt');

if rec_color
	fprintf(metadata_file,'Color stream:\n%i x %i pxs (%i bands)\nint8 ieee-%se\n',...
		FRAME_DESCRIPTION_PTR_COLOR.Width/color_downsample_fact,...
		FRAME_DESCRIPTION_PTR_COLOR.Height/color_downsample_fact,...
		length(color_bands),...
		lower(endian));
else
	fprintf(metadata_file,'Color stream: off\n');
end

fprintf(metadata_file,'Depth stream:\n%i x %i pxs\nint8 ieee-%se\n',...
	FRAME_DESCRIPTION_PTR_DEPTH.Width,...
	FRAME_DESCRIPTION_PTR_DEPTH.Height,...
	lower(endian));

[x,y,z]=ndgrid(color_bands,...
	1:color_downsample_fact:FRAME_DESCRIPTION_PTR_COLOR.Width,...
	1:color_downsample_fact:FRAME_DESCRIPTION_PTR_COLOR.Height);
idx_color=sub2ind([4 FRAME_DESCRIPTION_PTR_COLOR.Width FRAME_DESCRIPTION_PTR_COLOR.Height],x(:),y(:),z(:));

[x,y]=meshgrid(1:downsample_fact:FRAME_DESCRIPTION_PTR_DEPTH.Width,...
	1:downsample_fact:FRAME_DESCRIPTION_PTR_DEPTH.Height);
idx_depth=sub2ind([FRAME_DESCRIPTION_PTR_DEPTH.Width FRAME_DESCRIPTION_PTR_DEPTH.Height],x(:),y(:));

new_depth_res=[FRAME_DESCRIPTION_PTR_DEPTH.Height/downsample_fact,FRAME_DESCRIPTION_PTR_DEPTH.Width/downsample_fact];

preview_fig=figure('resize','off','menubar','none');
h=imagesc(zeros(new_depth_res(1),new_depth_res(2)));
axis off;
set(button_figure.nidaq,'visible','on');

cleanup_object=onCleanup(@()nyedack_s_cleanup_routine_kinect_v2([],[],....
  LOGFILE,NIDAQ_OBJECTS,NIDAQ_LISTENERS,...
	KINECT_ID,[ csv_file depth_file color_file metadata_file NIDAQ_FID ],...
	[ preview_fig button_figure.nidaq ]));

fprintf('done\n');
fprintf(csv_file,'%s, %s, %s, %s\n','Color','Color (tic)','Depth','Depth (tic)');

% timing is relative to the first trigger, align to session start as best as possible

startBackground(SESSION);
reference_tic=tic;

fprintf('Entering main acquisition loop...\n');

i=1;
while i<nframes

	if ~ishandle(button_figure.nidaq)
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
    end


	status1=1;
	status2=1;

	while status1~=0
		status1=calllib('KCBv2','KCBGetColorFrame',KINECT_ID,FRAME_PTR_COLOR);
		color_toc=toc(reference_tic);
    end

	while status2~=0
		status2=calllib('KCBv2','KCBGetDepthFrame',KINECT_ID,FRAME_PTR_DEPTH);
		depth_toc=toc(reference_tic);
	end

	if preview_mode && mod(i,frame_skip)==0
		depth_data=reshape(FRAME_PTR_DEPTH.Buffer(idx_depth),...
		[new_depth_res(1) new_depth_res(2)]);
		set(h,'cdata',depth_data);
		drawnow;
	end

	fprintf(csv_file,'%f, %f, %f, %f\n',...
	FRAME_PTR_COLOR.TimeStamp,color_toc,FRAME_PTR_DEPTH.TimeStamp,depth_toc);
	fwrite(depth_file,FRAME_PTR_DEPTH.Buffer,'int16'); % uses native format, can enforce

	if rec_color
		fwrite(color_file,FRAME_PTR_COLOR.Buffer(idx_color),'int8');
	end

	i=i+1;

end
