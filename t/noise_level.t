use strict;
no strict "vars";

use JCMT::SCUBA;

# ================================================================
#   Test JCMT::SCUBA::noise_level
#  
# ================================================================

$n=3; # number of tests
print "1..$n\n";

# === 1st Test: NOISE LEVEL bad parameters ===

($this,$stat) = noise_level(-1,450,'phot',100);

($stat==-1) && (print "ok\n") || (print "not ok\n");



# === 2nd Test: NOISE LEVEL wrong number of parameters ===

($this,$stat) = noise_level(10,100,'phot',100,10,10);

($stat==-2) && (print "ok\n") || (print "not ok\n");



# === 3rd Test: NOISE LEVEL ===

($this,$stat) = noise_level(100,850,'scan',100,10,10);
$this = sprintf("%.0lf",$this);

($stat==0) && ($this==11) && (print "ok\n") || (print "not ok\n");

