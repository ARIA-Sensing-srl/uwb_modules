pkg("load", "aria_uwb_toolbox");

#stop module before changes parameters
var_immediate_command("stop");

#USER PARAMETERS

#setup local variables
algo="DMAS_SR";
RhoStep = 0.05;                  	#Downrange resoluton
RhoRange = [1 6.0];              	#Downrange range
AzimStep = 5 * pi/180;         		#Aximuth angle resolution
AzimRange = [-45 45] * pi/180; 		#Azimuth angle range


staticObjRem=1;
var_immediate_update("staticObjRem");
staticObjMapUpdateTime=15.0;
var_immediate_update("staticObjMapUpdateTime");
profiles = 0;
var_immediate_update("profiles");
pause(0.5);


fps=15;
var_immediate_update("fps");

##END OF PARAMETERS###########################
xmin = RhoRange(1);				#minimum acquired distance
var_immediate_update("xmin");
xmax = RhoRange(2);
var_immediate_update("xmax");


#start radar operations
var_immediate_command("start");
