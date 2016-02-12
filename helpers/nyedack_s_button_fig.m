function [BUTTON_FIG,COMPONENTS]=nyedack_s_main(varargin)

fig_name='Push button v.001a';

nparams=length(varargin);

if mod(nparams,2)>0
	error('Parameters must be specified as parameter/value pairs!');
end

for i=1:2:nparams
  switch lower(varargin{i})
		case 'fig_name'
			fig_name=varargin{i+1};
		otherwise
	end
end

BUTTON_FIG=figure('Visible','off','Name',fig_name,...
	'Position',[200,500,300,250],'NumberTitle','off',...
	'menubar','none','resize','off');

COMPONENTS.status_text=uicontrol(BUTTON_FIG,'style','text',...
	'String','Status:  ',...
	'FontSize',12,...
	'ForegroundColor','k',...
	'units','normalized',...
	'FontWeight','bold',...
	'Position',[.1 .875 .7 .1]);

% TODO: add slot for device name and config?

COMPONENTS.stop_button=uicontrol(BUTTON_FIG,'style','pushbutton',...
	'String','Pause Acquisition',...
	'units','normalized',...
	'FontSize',12,...
	'Value',0,'Position',[.1 .5 .3 .3]);

COMPONENTS.start_button=uicontrol(BUTTON_FIG,'style','pushbutton',...
	'String','Resume Acquisition',...
	'units','normalized',...
	'FontSize',12,...
	'Value',0,'Position',[.5 .5 .3 .3]);

COMPONENTS.quit_button=uicontrol(BUTTON_FIG,'style','pushbutton',...
	'String','Quit Acquisition',...
	'units','normalized',...
	'FontSize',12,...
	'Value',0,'Position',[.1 .05 .7 .4]);
