#include <octave/oct.h>
// #include <octave/ov-struct.h>

DEFUN_DLD (oct_line_covered, args, ,
           "A .oct version of the mocov_line_covered function."){
  
  int nargin = args.length() ;

  octave_stdout << "This call has "  << nargin << " input arguments";

  octave_value_list retval(1);

  // if (nargin==0){
  
  //   octave_scalar_map st;
  //   st.assign ("keys", 1);
  //   st.assign ("line_count", 2);
  // }

  retval(0) = octave_value (Matrix ());
  return retval;
}