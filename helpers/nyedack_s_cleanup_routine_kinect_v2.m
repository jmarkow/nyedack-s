function cleanup_routine(obj,event,logfile,objects,listeners,kinect_id,kinect_files,kinect_figs)



% cleanup kinect

fprintf('Shutting down Kinect...\n');
kinect_v2_cleanup_routine([],[],kinect_id,kinect_files,kinect_figs);
pause(4); % make sure kinect if OFF before shutting down NIDAQ recording

disp('Cleaning up and quitting...');
fprintf(logfile,'\nRun complete at %s',datestr(now));
fclose(logfile);
warning('on','daq:general:nosave');

for i=1:length(objects)
	stop(objects{i});
	fprintf('Object %i (%s) isrunning %i\n',i,objects{i}.Vendor.ID,objects{i}.IsRunning);
end

for i=1:length(listeners)
	delete(listeners{i});
end
