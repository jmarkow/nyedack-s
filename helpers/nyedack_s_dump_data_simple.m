function nyedack_s_dump_data_simple(obj,event,fid)
% write to binary and get out

data = [event.TimeStamps, eventt.Data]' ;
fwrite(fid,data,'double');
