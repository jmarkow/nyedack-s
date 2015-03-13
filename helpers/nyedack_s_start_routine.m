function start_routine(obj,event,logfile,objects,status_text,start_button,stop_button)
%
%
%

disp('Resuming acquisition...');

for i=1:length(objects)
	startBackground(objects{i});
end

counter=0;
for i=1:length(objects)
	if objects{i}.IsRunning
		counter=counter+1;
	end
end

set(start_button,'enable','off');
set(stop_button,'enable','on');
set(status_text,'string','Status:  running','ForegroundColor','g');
disp(['Resumed ' num2str(counter) ' out of ' num2str(length(objects)) ' objects']);
fprintf(logfile,'\nRun restarted at %s\n',datestr(now));
