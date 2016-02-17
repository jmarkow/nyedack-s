function nyedack_s_dump_data_kinect(obj,event,filename,reference_tic)
% TODO: create another version that simply dumps to a text file by appending
% with option to use toc timestamps (will be critical for syncing)
% basically, a circular buffer is used!

%disp('Dumping data...');

% if getdata trips up clear the buffer and keep going!

% do we want to preview?

reference_ts=toc(reference_tic);
nchannels=length(obj.Channels);

% write the data, get out of dodge

fwrite('%f, %f, ',event.TimeStamps,reference_ts)
for i=1:nchannels-1
  fwrite('%f,',event.Data(1,i));
end
fwrite('%f\n',event.Data(1,nchannels));
