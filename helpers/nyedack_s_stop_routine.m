function stop_routine(obj,event,logfile,objects,status_text,start_button,stop_button)
%
%
%

disp('Pausing acquisition...');

for i=1:length(objects)
	stop(objects{i});
end

for i=1:length(objects)
	fprintf('Object %i (%s) isrunning %i\n',i,objects{i}.Vendor.ID,objects{i}.IsRunning);
end


set(start_button,'enable','on');
set(stop_button,'enable','off');
set(status_text,'string','Status:  stopped','ForegroundColor','r');
fprintf(logfile,'\nRun stopped at %s',datestr(now));

