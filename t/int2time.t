use strict;
no strict "vars";

use JCMT::SCUBA;

# ================================================================
#   Test JCMT::SCUBA::int2time
#  
# ================================================================

$n=2; # number of tests
print "1..$n\n";

# === 1st Test: INT2TIME bad parameters ===

($this,$stat) = int2time(-10,'phot');

($stat==-1) && (print "ok\n") || (print "not ok\n");



# === 2nd Test: INT2TIME ===

($this,$stat) = int2time( 100, 'phot' );
$this = sprintf("%.0lf",$this);

($stat==0) && ($this == 1800) && (print "ok\n") || (print "not ok\n");

