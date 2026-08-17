pkg("load", "aria_uwb_toolbox");

#stop module before changes parameters
var_immediate_command_pipe("stop");

#USER PARAMETERS

#setup local variables
RhoStep = 0.07;                  	#Downrange resoluton
RhoRange = [1 6.0];              	#Downrange range
AzimStep = 5 * pi/180;         		#Azimuth angle resolution
AzimRange = [-45 45] * pi/180; 		#Azimuth angle range


staticObjRem=1;				#Static object removal algorithm, de-clutter
var_immediate_update_pipe("staticObjRem");
staticObjMapUpdateTime=15.0;		#Clutter map update time constant
var_immediate_update_pipe("staticObjMapUpdateTime");
profiles = 0;
var_immediate_update_pipe("profiles");
pause(0.5);

xmin = RhoRange(1);				#minimum acquired distance
var_immediate_update_pipe("xmin");
xmax = RhoRange(2);				#maximum acquired distance
var_immediate_update_pipe("xmax");
fps=15;						#frame rate
var_immediate_update_pipe("fps");

##END OF PARAMETERS###########################


#start radar operations
var_immediate_command_pipe("start");
