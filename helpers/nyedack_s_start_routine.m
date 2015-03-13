function start_routine(obj,event,logfile,objects,status_text,start_button,stop_button)
%
%
%

disp('Resuming acquisition...');

for i=1:length(objects)
	startBackground(objects{i});
end

for i=1:length(objects)
	fprintf('Object %i (%s) isrunning %i\n',i,objects{i}.Vendor.ID,objects{i}.IsRunning);
end

set(start_button,'enable','off');
set(stop_button,'enable','on');
set(status_text,'string','Status:  running','ForegroundColor','g');
fprintf(logfile,'\nRun restarted at %s\n',datestr(now));
