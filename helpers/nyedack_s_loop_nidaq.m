function nyedack_s_loop_nidaq(SESSION,OBJECTS,LISTENERS,LOGFILE,SAVE_DIR)
%
%
%
%


[button_figure,components]=nyedack_s_button_fig('fig_name','NyeDack Acquition');

% add figure for output as well

set(components.stop_button,'call',...
	{@nyedack_s_stop_routine,LOGFILE,OBJECTS,components.status_text,components.start_button,components.stop_button});
set(components.start_button,'call',...
	{@nyedack_s_start_routine,LOGFILE,OBJECTS,components.status_text,components.start_button,components.stop_button});

% refresh rate of scope determined by TimerPeriod

set(components.quit_button,'call',...
	{@nyedack_s_early_quit,button_figure});

warning('off','daq:general:nosave');

set(button_figure,'Visible','on');
cleanup_object=onCleanup(@()nyedack_s_cleanup_routine([],[],SAVE_DIR,LOGFILE,OBJECTS,LISTENERS,button_figure));

% options for separate loops (just NiDaq, NiDaq+Kinect, etc. )

startBackground(SESSION);
set(components.status_text,'string','Status:  running','ForegroundColor','g');

while 1>0

	if ~ishandle(button_figure), break; end

	flag=1;
	for i=1:length(OBJECTS)
		if ~OBJECTS{i}.IsRunning
			flag=0;
			break;
		end
	end

	if flag
		set(components.status_text,'string','Status:  running','ForegroundColor','g');
	else
		set(components.status_text,'string','Status:  stopped','ForegroundColor','r');
	end

	pause(.1);

end
