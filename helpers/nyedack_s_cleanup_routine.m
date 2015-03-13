function cleanup_routine(obj,event,save_directory,logfile,objects,button_figure,listeners)

disp('Cleaning up and quitting...');

fprintf(logfile,'\nRun complete at %s',datestr(now));
fclose(logfile);
warning('on','daq:general:nosave');

for i=1:length(objects)
	stop(objects{i});
	disp(['Object ' num2str(i) ' isrunning:  ' num2str(objects{i}.IsRunning)]);
end

disp('Run complete!');

if nargin==6
	if ishandle(button_figure)
		delete(button_figure);
	end
end

for i=1:length(listeners)
	delete(listeners{i});
end
