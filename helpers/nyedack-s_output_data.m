function output_data(obj,event,logfile,output_data)
%
%

trigger(obj);
fprintf(logfile,'Triggered at %s\n', datestr(now));
disp(['Trigger event occurred at ' datestr(now)]);
putdata(obj,output_data);


