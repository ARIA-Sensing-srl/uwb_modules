clear all;


base_root = "C:/A/ARIA_RDK_WIN/share/octave/9.4.0/m/";
addpath(genpath(base_root));
pkg_name = "general";
addpath(sprintf("%s%s", base_root,pkg_name));

base_packs =  {"general","help","io","linear-algebra","miscellaneous","path","set","specfun","strings","time","statistics"};

for n=base_packs  
  pkg_name = cell2mat(n);
  printf("added %s \n", pkg_name);
  addpath(genpath(sprintf("%s%s", base_root,pkg_name)));
endfor;

