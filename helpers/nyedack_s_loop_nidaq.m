function nyedack_s_loop_nidaq(SESSION,BUTTON_FIGURE,COMPONENTS,OBJECTS,LISTENERS,LOGFILE,SAVE_DIR)
%
%
%
%


[BUTTON_FIGURE,COMPONENTS]=nyedack_s_button_fig('fig_name','NyeDack Acquition');

% add figure for output as well

set(COMPONENTS.stop_button,'call',...
	{@nyedack_s_stop_routine,LOGFILE,OBJECTS,COMPONENTS.status_text,COMPONENTS.start_button,COMPONENTS.stop_button});
set(COMPONENTS.start_button,'call',...
	{@nyedack_s_start_routine,LOGFILE,OBJECTS,COMPONENTS.status_text,COMPONENTS.start_button,COMPONENTS.stop_button});

% refresh rate of scope determined by TimerPeriod

set(COMPONENTS.quit_button,'call',...
	{@nyedack_s_early_quit,BUTTON_FIGURE});

warning('off','daq:general:nosave');

set(BUTTON_FIGURE,'Visible','on');
cleanup_object=onCleanup(@()nyedack_s_cleanup_routine([],[],SAVE_DIR,LOGFILE,OBJECTS,LISTENERS,BUTTON_FIGURE));

% options for separate loops (just NiDaq, NiDaq+Kinect, etc. )

startBackground(SESSION);
set(COMPONENTS.status_text,'string','Status:  running','ForegroundColor','g');

while 1>0

	if ~ishandle(BUTTON_FIGURE), break; end

	flag=1;
	for i=1:length(OBJECTS)
		if ~OBJECTS{i}.IsRunning
			flag=0;
			break;
		end
	end

	if flag
		set(COMPONENTS.status_text,'string','Status:  running','ForegroundColor','g');
	else
		set(COMPONENTS.status_text,'string','Status:  stopped','ForegroundColor','r');
	end

	pause(.1);

end
