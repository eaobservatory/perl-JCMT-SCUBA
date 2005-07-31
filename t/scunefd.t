use strict;
use Test::More tests => 15;

BEGIN {
  use_ok( "JCMT::SCUBA" );
}

# ================================================================
#   Test JCMT::SCUBA::scunefd 
#  
#    Important note -- if the fitted NEFD curve values are updated
#    some of the tests will fail!
#
# ================================================================

# === 1st Test: SCUNEFD boundary ===

my ($this,$stat) = scunefd(350,.01);

is( $stat, -2, "Check status for 350");

# === 2nd Test: SCUNEFD bad parameters ===

($this,$stat) = scunefd(-1,.2);

is( $stat, -1, "Check deliberate bad status");

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
  print "# Result at $wave with sky trans of $trans is $this mJy\n";
  is( $stat, 0, "Check good status for $wave vs $trans" );
  is( $result, $this, "Check result for $wave at $trans");
}
