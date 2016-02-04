function cleanup_routine(obj,event,save_directory,logfile,objects,listeners,button_figure,kinect_objects,kinect_files,kinect_figs)

disp('Cleaning up and quitting...');

fprintf(logfile,'\nRun complete at %s',datestr(now));
fclose(logfile);
warning('on','daq:general:nosave');

for i=1:length(objects)
	stop(objects{i});
	fprintf('Object %i (%s) isrunning %i\n',i,objects{i}.Vendor.ID,objects{i}.IsRunning);
end

disp('Run complete!');

figs=fieldnames(button_figure);
for i=1:length(figs)
	if isfield(button_figure,figs{i}) & ishandle(button_figure.(figs{i}))
		delete(button_figure.(figs{i}));
	end
end

for i=1:length(listeners)
	delete(listeners{i});
end

for i=1:length(kinect_figs)
	if ishandle(kinect_figs(i))
		delete(kinect_figs(i));
	end
end

for i=1:length(kinect_files)
	fclose(kinect_files(i));
end
