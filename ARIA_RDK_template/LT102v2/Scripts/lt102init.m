#init procedure
#pkg load aria_uwb_toolbox
min_range = 0.2;
var_immediate_update("min_range");
max_range = 2;
var_immediate_update("max_range");
elaboration = 1; #3 det, 2 MTI env
var_immediate_update("elaboration");
threshold = 2.0;
var_immediate_update("threshold");
histLgth = 100;
dethist = zeros(1,histLgth);
fast_decl_const = 10;
norm_decl_const = 200;
declutter_length = fast_decl_const;
var_immediate_update("declutter_length");
init = tic();

var_immediate_command("start");