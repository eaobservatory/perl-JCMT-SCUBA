use strict;
no strict "vars";

use JCMT::SCUBA;

# ================================================================
#   Test JCMT::SCUBA::int_time
#  
# ================================================================

$n=3; # number of tests
print "1..$n\n";

# === 1st Test: INT TIME bad parameters ===

($this,$stat) = int_time(10,450,'snork',100);

($stat==-1) && (print "ok\n") || (print "not ok\n");



# === 2nd Test: INT TIME wrong number of parameters ===

($this,$stat) = int_time(10,100,'phot',100,10,10);

($stat==-2) && (print "ok\n") || (print "not ok\n");



# === 3rd Test: INT TIME ===

($this,$stat) = int_time(5,850,'scan',100,10,10);
$this = sprintf("%.0lf",$this);

($stat==0) && ($this==444) && (print "ok\n") || (print "not ok\n");
