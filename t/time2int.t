use strict;
no strict "vars";

use JCMT::SCUBA;

# ================================================================
#   Test JCMT::SCUBA calls
#  
# ================================================================

$n=2; # number of tests
print "1..$n\n";

# === 1st Test: TIME2INT bad parameters ===

($this,$stat) = time2int(-10,'phot');

($stat==-1) && (print "ok\n") || (print "not ok\n");



# === 2nd Test: TIME2INT ===

($this,$stat) = time2int( 100, 'phot' );

($stat==0) && ($this==6) && (print "ok\n") || (print "not ok\n");


