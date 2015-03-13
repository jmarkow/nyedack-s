function restart_routine(obj,event,logfile,objects,status_text,start_button,stop_button)

disp('Error occurred, restarting the acquisition...')

fprintf(logfile,'\nError encountered at%s\n',datestr(now));
disp('Stopping all objects and flushing data');

for i=1:length(objects)
	stop(objects{i});
	flushdata(objects{i});
end

counter=0;
for i=1:length(objects)
	if strcmpi(get(objects{i},'Running'),'Off')
		counter=counter+1;
	end
end

disp(['Stopped ' num2str(counter) ' out of ' num2str(length(objects)) ' objects']);

disp('Pausing for ten seconds...');

set(start_button,'enable','off');
set(stop_button,'enable','off');
pause(10);
set(status_text,'string','Status:  error (pausing and restarting)','ForegroundColor','g');

for i=1:length(objects)
	start(objects{i});
end

counter=0;
for i=1:length(objects)
	if strcmpi(get(objects{i},'Running'),'On')
		counter=counter+1;
	end
end

disp(['Resumed ' num2str(counter) ' out of ' num2str(length(objects)) ' objects']);

set(start_button,'enable','off');
set(stop_button,'enable','on');

set(status_text,'string','Status:  running','ForegroundColor','g');
fprintf(logfile,'\nRun restarted at %s\n',datestr(now));
