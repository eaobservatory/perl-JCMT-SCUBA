use strict;
no strict "vars";

use JCMT::SCUBA;

# ================================================================
#   Test JCMT::SCUBA::overhead
#  
# ================================================================

$n=2; # number of tests
print "1..$n\n";

# === 1st Test: OVERHEAD bad parameters ===

($this,$stat) = overhead(10,'999');

($stat==-1) && (print "ok\n") || (print "not ok\n");


# === 2nd Test: OVERHEAD ===

($this,$stat) = overhead(20,'phot');
$this = sprintf("%.0lf",$this);

($stat==0) && ($this==200) && (print "ok\n") || (print "not ok\n");
