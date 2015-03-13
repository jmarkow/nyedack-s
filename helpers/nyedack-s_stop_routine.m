function stop_routine(obj,event,logfile,objects,status_text,start_button,stop_button)
%
%
%

disp('Pausing acquisition...');

for i=1:length(objects)
	stop(objects{i});
end

counter=0;
for i=1:length(objects)
	if strcmpi(get(objects{i},'Running'),'Off')
		counter=counter+1;
	end
end


set(start_button,'enable','on');
set(stop_button,'enable','off');
set(status_text,'string','Status:  stopped','ForegroundColor','r');
disp(['Stopped ' num2str(counter) ' out of ' num2str(length(objects)) ' objects']);
fprintf(logfile,'\nRun stopped at %s',datestr(now));

