#grab data
var_immediate_inquiry("data");

#fast_decl_const = 10;
#norm_decl_const = 200;
#declutter_length = fast_decl_const;
#var_immediate_update("declutter_length");
#init = tic();
if (declutter_length != norm_decl_const)
   elaps = toc(init);
   if (elaps > 5)
       printf("End fast declutter\n");
       declutter_length = norm_decl_const;
       var_immediate_update("declutter_length");
   end
end