use strict;
no strict "vars";

use JCMT::SCUBA;

# ================================================================
#   Test JCMT::SCUBA::scunefd 
#  
# ================================================================

$n=3; # number of tests
print "1..$n\n";

# === 1st Test: SCUNEFD boundary ===

($this,$stat) = scunefd(350,.01);

($stat==-2) && (print "ok\n") || (print "not ok\n");



# === 2nd Test: SCUNEFD bad parameters ===

($this,$stat) = scunefd(-1,.2);

($stat==-1) && (print "ok\n") || (print "not ok\n");



# === 3rd Test: SCUNEFD ===

($this,$stat) = scunefd(450,.5);
$this = sprintf("%.0lf",$this);

($stat==0) && ($this== 431) && (print "ok\n") || (print "not ok\n");
