use strict;
no strict "vars";

use JCMT::SCUBA;

# ================================================================
#   Test JCMT::SCUBA::scunefd 
#  
#    Important note -- if the fitted NEFD curve values are updated
#    some of the tests will fail!
#
# ================================================================

$n=8; # number of tests
print "1..$n\n";

# === 1st Test: SCUNEFD boundary ===

($this,$stat) = scunefd(350,.01);

($stat==-2) && (print "ok\n") || (print "not ok\n");



# === 2nd Test: SCUNEFD bad parameters ===

($this,$stat) = scunefd(-1,.2);

($stat==-1) && (print "ok\n") || (print "not ok\n");



# === 3rd Test: SCUNEFD at 450 ===

&testnefd(450, 0.5, 489);
&testnefd(450, 0.25, 901);

# === 4rd Test: SCUNEFD at 750 ===

&testnefd(750, 0.3, 496);

# === 5rd Test: SCUNEFD at 350 ===

&testnefd(350, 0.25, 1520);

# === 6rd Test: SCUNEFD at 850 ===

&testnefd(850, 0.85, 75);
&testnefd(850, 0.3, 262);


sub testnefd {
  my ($wave, $trans, $result)= @_;

  my ($this,$stat) = scunefd($wave, $trans);
  $this = sprintf("%.0lf",$this);
  print "Result at $wave with sky trans of $trans is $this mJy\n";

  ($stat==0) && ($this== $result) && (print "ok\n") || (print "not ok\n");
}
