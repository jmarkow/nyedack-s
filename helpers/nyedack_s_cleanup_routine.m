function cleanup_routine(obj,event,save_directory,logfile,objects,button_figure,preview_figure)

disp('Cleaning up and quitting...');

fprintf(logfile,'\nRun complete at %s',datestr(now));
fclose(logfile);

for i=1:length(objects)
	stop(objects{i});
end

disp('Run complete!');

if nargin==6
	if ishandle(button_figure)
		delete(button_figure);
	end
end

if nargin==7 
	if ishandle(preview_figure)
		delete(preview_figure);
	end
end


