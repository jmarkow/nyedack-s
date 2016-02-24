function nyedack_s_loop_nidaq_kinect_v2(SESSION,NIDAQ_OBJECTS,NIDAQ_LISTENERS,LOGFILE,NIDAQ_FID,FILENAME,varargin)

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

% height width

color_res=[1080 1920];
depth_res=[424 512];

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


fprintf('done\n');
fprintf(csv_file,'%s, %s, %s, %s\n','Color','Color (tic)','Depth','Depth (tic)');

% timing is relative to the first trigger, align to session start as best as possible
% initialize depth and color streams

%%% manually set up kinect, need to leave IR sensor OFF until we can capture a frame...

kin_id=calllib('KCBv2','KCBOpenDefaultSensor');

frame_color=kinect_v2_make_struct('KCBColorFrame');
frame_ptr_color=libstruct('KCBColorFrame',frame_color);
frame_ptr_color.Size=color_res(1)*color_res(2)*4;
frame_ptr_color.Format='ColorImageFormat_Rgba';
frame_ptr_color.Buffer=zeros(frame_ptr_color.Size,1,'uint8');

frame_depth=kinect_v2_make_struct('KCBDepthFrame');
frame_ptr_depth=libstruct('KCBDepthFrame',frame_depth);
frame_ptr_depth.Size=depth_res(1)*depth_res(2);
frame_ptr_depth.Buffer=zeros(frame_ptr_depth.Size,1,'uint16');

if rec_color
	fprintf(metadata_file,'Color stream:\n%i x %i pxs (%i bands)\nint8 ieee-%se\n',...
		color_res(2)/color_downsample_fact,...
		color_res(1)/color_downsample_fact,...
		length(color_bands),...
		lower(endian));
else
	fprintf(metadata_file,'Color stream: off\n');
end

fprintf(metadata_file,'Depth stream:\n%i x %i pxs\nint8 ieee-%se\n',...
	depth_res(2),...
	depth_res(1),...
	lower(endian));

[x,y,z]=ndgrid(color_bands,...
	1:color_downsample_fact:color_res(2),...
	1:color_downsample_fact:color_res(1));
idx_color=sub2ind([4 color_res(2) color_res(1)],x(:),y(:),z(:));

[x,y]=meshgrid(1:downsample_fact:depth_res(2),...
	1:downsample_fact:depth_res(1));
idx_depth=sub2ind([depth_res(2) depth_res(1)],x(:),y(:));

new_depth_res=[depth_res(1)/downsample_fact,depth_res(2)/downsample_fact];

preview_fig=figure('resize','off','menubar','none');
h=imagesc(zeros(new_depth_res(1),new_depth_res(2)));
axis off;
set(button_figure.nidaq,'visible','on');

cleanup_object=onCleanup(@()nyedack_s_cleanup_routine_kinect_v2([],[],....
  LOGFILE,NIDAQ_OBJECTS,NIDAQ_LISTENERS,...
	kin_id,[ csv_file depth_file color_file metadata_file NIDAQ_FID ],...
	[ preview_fig button_figure.nidaq ]));

fprintf('Entering main acquisition loop...\n');
i=1;

% try toggling kinect to get rid of this startup slop...

while i<nframes

	% force nidaq values to 0 until second loop around?????

	if ~ishandle(button_figure.nidaq)
		break;
    end

	% after a small number of warmup frames, turn on NiDAQ

  if i==5
      startBackground(SESSION);
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
		status1=calllib('KCBv2','KCBGetColorFrame',kin_id,frame_ptr_color);
	end

	% set something in userdata to on?

  color_toc=toc(reference_tic);

  while status2~=0
      status2=calllib('KCBv2','KCBGetDepthFrame',kin_id,frame_ptr_depth);
  end

  depth_toc=toc(reference_tic);

	if preview_mode && mod(i,frame_skip)==0
		depth_data=reshape(frame_ptr_depth.Buffer(idx_depth),...
		[new_depth_res(1) new_depth_res(2)]);
		set(h,'cdata',depth_data);
		drawnow;
	end

	fprintf(csv_file,'%f, %f, %f, %f\n',...
        frame_ptr_color.TimeStamp,color_toc,frame_ptr_depth.TimeStamp,depth_toc);
	%fwrite(depth_file,frame_ptr_depth.Buffer,'int16'); % uses native format, can enforce

	if rec_color
		fwrite(color_file,frame_ptr_color.Buffer(idx_color),'int8');
	end

	i=i+1;

end

% stop nidaq first?

fprintf('Frame count %i, warmup frames %i\n',i)
fprintf('Stopping Kinect...');
kinect_v2_close(kin_id);
pause(5);
stop(SESSION);
fprintf('done\n');
