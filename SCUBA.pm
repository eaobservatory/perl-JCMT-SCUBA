package JCMT::SCUBA;

#------------------------------------------------------------------------------

=head1 NAME

JCMT::SCUBA - Module containing functions which deal specifically with SCUBA.

=head1 SYNOPSIS

use JCMT::SCUBA;

=head1 DESCRIPTION

This module is comprised of code originally used to create the Integration
Time Calculator (http://www.jach.hawaii.edu/jcmt_sw/bin/itc.pl). The functions
that are supplied can be used to find the NEFD of SCUBA at different 
wavelengths and sky transmissions, to find the integration time required in a
certain mode to attain a desired noise level, and to perform the inverse 
calculation where an attainable noise level may be determined from an 
integration time. There is also a function to determine the overhead time for
a given integration time.

=cut

#------------------------------------------------------------------------------

use strict;
use vars qw($VERSION @ISA @EXPORT);

$VERSION = "1.11";

require Exporter;

@ISA = qw(Exporter);
@EXPORT = qw(scunefd overhead int_time noise_level time2int int2time);

#------------------------------------------------------------------------------
#                            *** Functions ***
#------------------------------------------------------------------------------

=head1 FUNCTION CALLS

At present, all the functions are imported when the module is used:

        scunefd: find NEFD for scuba as a function of wavelength and 
                 atmospheric transmission

       overhead: calculate the overhead on an observation given the
                 observation mode and integration time.

       int_time: calculate the integration time required to achieve a 
                 desired noise level.

    noise_level: find the noise level that will be attained by integrating
                 for a certain ammount of time.

       time2int: find how many integrations are required to integrate for
                 a given number of seconds.

       int2time: find out how long it takes to perform a given number of
                 integrations (not including overhead).

=cut

#------------------------------------------------------------------------------

=head2 SCUBA NEFD:

If you want to find the NEFD of SCUBA at a certain transmission and wavelength,
do the following:

  ($nefd,$status) = scunefd($wavelength,$trans);

=head2 Parameters

=over

=item 1.

The first parameter is the wavelength in microns, which can be '350', '450', '750', '850', '1350' or '2000'

=item 2.

The second parameter is the sky transmission coefficient at the given 
wavelength. This may be derived using JCMT::Tau::transmission from sky opacity
and airmass.

*Note: Only the average NEFD is known for the photometry pixels at 1350 and 
2000 microns, so the transmission will have no effect on the values at these 
wavelengths.

=back

=head2 Return Values

scunefd returns a 2-element list. The first element is the NEFD coefficient 
at the indicated wavelength. The second is a scalar containing the exit status
of the function:

  status = 0: successful
          -1: failure due to invalid parameters
          -2: bad value because transmission out of range of 
              fit

=cut

#------------------------------------------------------------------------------

# Table which stores constant NEFD values for different filters:

my %nefd_table = ( 
		  '2000' => 120,
		  '1350' => 60,
		 );

sub scunefd ($$) {

  # Some of the fits use a 10th order polynomial and some use a simple
  # power law

  # Lists whether we have a power law version of the fit
  my %USEPOWER = (
		  850  => 1,
		  450  => 1,
		  350  => 0,
		  750  => 0,
		  2000 => 0,
		  1350 => 0,
		 );

  # Store these as parameters of a simple power law  NEFD = a x^b

  my %POWERLAW = (
		  850 => [ 62.13036,  -1.19450 ], # wideband
		  450 => [ 265.22623, -0.88198 ], # wideband
		 );

  # The coefficients stuff needs to be hacked to make it a bit more
  # obvious -- should probably convert them all to power laws
  # Store the coefficients of the 10th order fits for the NEFD vs transmission
  # curves. Fit is good on the interval (0.042,0.641) for 450 microns,
  # (0.038,0.937) for 850 microns, (0.038,0.437) for 350 microns, (0.038,0.875)
  # for 750 microns. Each curve has two fits - one for the curvey part at the
  # beginning, and another for the straight part later. This was introduced to
  # reduce the waviness caused later by the initial curviness. How scientific.

  # 450: < .25
  my @COEFF450_1 = (31481.3782, -1443452.4, 37587422.2, -622243777, 
		    6.89288759e+09, -5.22809174e+10, 2.7230432e+11, 
		    -9.57251741e+11, 2.16914012e+12, -2.85909821e+12,
		    1.66471902e+12);

  # 450: >= .25
  my @COEFF450_2 = (1398.42405, 47297.8604, -687552.05, 4106666.55, 
		    -13058035.6, 20679439.3, -2303458.01, -52848760.7, 
		    96780620.5, -75797136.7, 23242534);

  # 850: < .4
  my @COEFF850_1 = (12437.1852, -460404.695, 9321936.98, -116452272, 949460006,
		    -5.19307203e+09, 1.91830323e+10, -4.71851636e+10,
		    7.3996495e+10, -6.68951861e+10, 2.65178399e+10);

  # 850: >= .4
  my @COEFF850_2 = (1916.91829, -12209.0652, 39905.7003, -72395.673, 
		    58575.4075, 24271.7059, -93325.9314, 64243.6412, 
		    5940.05505, -25228.7225, 8364.3555);

  # 350: < .2
  my @COEFF350_1 = (48781.2086, -2257045.6, 57372483.6, -876500659, 
		    8.02746219e+09, -3.79248127e+10, -2.99837363e+09,
		    1.1429173e+12, -6.59462154e+12, 1.67617625e+13,
		    -1.68313616e+13);

  # 350: >= .2
  my @COEFF350_2 = (4098.53825, 44223.7807, -878256.106, 5201060.54, 
		    -12535618.9, 1480625.25, 35235905.7, 50099615, 
		    -423756300, 705809349, -393468673);

  # 750: < .4
  my @COEFF750_1 = (16767.0584, -630783.391, 13015863.5, -166075120, 
		    1.38549852e+09, -7.76512034e+09, 2.94254867e+10,
		    -7.43149661e+10, 1.1974169e+11, -1.11282628e+11, 
		    4.53684768e+10);

  # 750: >= .4
  my @COEFF750_2 = (2324.86396, -12506.7929, 27839.396, -6118.9046, 
		    -97065.4346, 168324.253, 22767.7548, -398552.827, 
		    533122.588, -310784.71, 70736.76);

  # Calculate the NEFD as a function of transmission. First parameter is 
  # wavelength (450, 850, 350 or 750 microns) and second parameter is sky 
  # transmission coeff. 

  my ($i,$val,$thisarray);
  my $status = 0;

  # Handle constant NEFD cases

  if (defined $nefd_table{$_[0]}) {
    return $nefd_table{$_[0]},0;
  }

  # See if transmission is reasonable (i.e. between 0 and 1)

  unless ( $_[1]>=0 ) {
    return (0,-1);
  }

  # Decide which coefficients to use

  SWITCH: {

    if ($_[0]==450) {

      if ($_[1] < .25) { $thisarray = \@COEFF450_1; }
      else { $thisarray = \@COEFF450_2; }

      if ($USEPOWER{$_[0]} && exists $POWERLAW{$_[0]}) {
	$thisarray = $POWERLAW{$_[0]};
      }

      # See if transmission on interval of fit

      if ( $_[1]<.042 || $_[1]>.641 ) {
	$status = -2;
      }

      last SWITCH;
    }

    if ($_[0]==850) {
      
      if ($_[1] < .4) {	$thisarray = \@COEFF850_1; }
      else { $thisarray = \@COEFF850_2; }

      if ($USEPOWER{$_[0]} && exists $POWERLAW{$_[0]}) {
	$thisarray = $POWERLAW{$_[0]};
      }

      # See if transmission on interval of fit

      if ( $_[1]<.038 || $_[1]>.937 ) {
	$status = -2;
      }

      last SWITCH;
    }

    if ($_[0]==350) {

      if ($_[1] < .2) {	$thisarray = \@COEFF350_1; }
      else { $thisarray = \@COEFF350_2; }

      if ($USEPOWER{$_[0]} && exists $POWERLAW{$_[0]}) {
	$thisarray = $POWERLAW{$_[0]};
      }

      # See if transmission on interval of fit

      if ( $_[1]<.038 || $_[1]>.437 ) {
	$status = -2;
      }

      last SWITCH;
    }

    if ($_[0]==750) {

      if ($_[1] < .4) {	$thisarray = \@COEFF750_1; }
      else { $thisarray = \@COEFF750_2; }

      if ($USEPOWER{$_[0]} && exists $POWERLAW{$_[0]}) {
	$thisarray = $POWERLAW{$_[0]};
      }

      # See if transmission on interval of fit

      if ( $_[1]<.038 || $_[1]>.875 ) {
	$status = -2;
      }

      last SWITCH;
    }

    return (0,-1);
  }

  # now evaluate the power series or the powerlaw

  if ($USEPOWER{$_[0]}) {
    $val = $thisarray->[0] * ($_[1] ** $thisarray->[1]);
  } else {
    $val = 0;
    for ($i=0; $i<=10; $i++) {
      $val += $$thisarray[$i]*$_[1]**$i;
    }
  }

  return ($val,$status);
}

#------------------------------------------------------------------------------

=head2 OVERHEAD:

To find the ammount of overhead in seconds for an observation when you know the
number of integrations:

  ($overhead,$status) = overhead($integrations,$mode);

=head2 Parameters

=over

=item 1.

The first parameter is the number of integrations. 

=item 2.

The second parameter is the observation mode, which may be one of the 
following:

  'phot'  = photometry
  'jig16' = 16 point jiggle map
  'jig64' = 64 point jiggle map

Presently scan mapping is not supported by this function because we do not 
know how to properly estimate the overhead, and also it is difficult to attach
meaning to 'integrations' in this mode. It should be noted however that a 
rough estimate for overhead in scan mapping is 50% of the integration time.

Similarly, polarimetry is not supported. A rough guess is 50% overhead.

=back

=head2 Return Values

overhead returns a 2-element list. The first element is the over head in 
number of seconds. The second is a scalar containing the exit status of the 
function:

  status = 0: successful
          -1: failure due to invalid parameters

=cut

#------------------------------------------------------------------------------

sub overhead ($$) {

  my $integration = $_[0];
  my $mode = uc $_[1];
  my $overhead;

  # want a positive number of integrations

  if ($integration <= 0) {
    return (0,-1);
  }

  CASE: {
    
    # --- First Case: Photometry ---

    if ($mode eq 'PHOT') {

      # note: number of exposures = number of integrations
      
      my $switch = $integration*2;
     
      $overhead = 40 + $switch*2.5 + $integration*3;
     
      last CASE;
    }
   
    # --- Second Case: 64 Pt. Jiggle ---
   
    if ($mode eq 'JIG64') {
     
      my $exposure = $integration*4;
      my $switch = $exposure*2;
      
      $overhead = 40 + $switch*3 + $exposure*3;
      
      last CASE;
    }
    
    # --- Third Case: 16 Pt. Jiggle ---
    
    if ($mode eq 'JIG16') {
      
      # note: number of exposures = number of integrations
      
      my $switch = $integration*2;
      
      $overhead = 40 + $switch*3 + $integration*3;
      
      last CASE;
    }
    
    # Bad exit status if none of the instruments matched
    
    return (0,-1);
  }
 
  # Good exit status

  return ($overhead,0);

}

#------------------------------------------------------------------------------

=head2 NOISE LEVEL:

If you want to see what kind of noise level you can achieve with a certain
integration time, do the following:

  ($noise,$status) = noise_level($int,$filter,$mode,$nefd);

    or

  ($noise,$status) = 
    noise_level($int,$filter,$mode,$nefd,$length,$width);

The first case is for jiggle mapping, photometry and polarimetry. The second 
is for scan mapping, where map dimensions must be specified. 

=head2 Parameters

=over

=item 1.

The first parameter is the integration time. 

=item 2.

The second parameter is the filter wavelength in microns, which is one of 
'350','450','750','850','1350' or '2000'

=item 3.

The third parameter is the observation mode, which may be one of the following:

  'phot'  = photometry
  'jig16' = 16 point jiggle map
  'jig64' = 64 point jiggle map
  'scan'  = scan mapping 
  'pol'   = polarimetry

Scan mapping requires additional parameters. See 5th and 6th parameters.

=item 4.

The fourth parameter is the NEFD of SCUBA for a given atmospheric transmission
and filter wavelength. (see the function JCMT::SCUBA::scunefd).

=item 5. & 6.

If scan mapping, the last two parameters are the length and width of the map in
in arcseconds. Length in this case means in the direction of the scan.

=back

=head2 Return Values

noise_level returns a 2-element list. The first element is the noise level in
mJy. The second is a scalar containing the exit status of the function:

  status = 0: successful
          -1: failure due to invalid parameters
          -2: incorrect number of parameters

=cut

#------------------------------------------------------------------------------

sub noise_level {

  my $int = $_[0];
  my $filter = $_[1];
  my $mode = uc $_[2];
  my $nefd = $_[3];
  my ($length,$width,$status,$noise);

  # Need map dimensions if scan mapping

  if ($mode eq 'SCAN') {

    # First see that we have the right # of parameters

    unless ($#_ == 5) {
      return (0,-2);
    }

    $length = $_[4];
    $width = $_[5];

    # now check dimensions

    if ($length <= 0 || $width <= 0) {
      return (0,-1);
    }
  }

  # Otherwise we only need 4 parameters

  elsif ($#_ != 3) {
    return (0,-2);
  }

  # Make sure we have positive integration time

  unless ($int > 0) {
    return (0,-1);
  }
  
  # Check NEFD value

  unless ($nefd > 0) {
    return (0,-1);
  }

  # Basic noise calculation

  $noise = $nefd / sqrt($int);

  # Now we have special factors for different modes:

  CASE: {

    # --- 1st Case ---  Photometry (no factor)

    if ($mode eq 'PHOT') {
      last CASE;
    }
	    
    # --- 2nd Case ---  Jiggle Mapping (factor of 4)
    
    if ($mode eq 'JIG16' || $mode eq 'JIG64') {
      $noise *= 4;
      last CASE;
    }
    
    # --- 3rd Case --- Scan Map 
    
    if ($mode eq 'SCAN') {
      
      $noise *= sqrt((138+$length)*$width/9);
      
      if ($filter eq '350' || $filter eq '450') {
	$noise /= sqrt(91);
	last CASE;
      }
      
      elsif ($filter eq '750' || $filter eq '850') {
	$noise /= sqrt(37*4);
	last CASE;
      }
    }

    # --- 4th Case --- Polarimetry 
	
    if ($mode eq 'POL') {
      $noise *= sqrt(18);
      last CASE;
    }

    # --- if no match bad exit status ---
	
    return (0,-1);
    
  } # --- End of Case Statement ---

  return ($noise,0);

}

#------------------------------------------------------------------------------

=head2 INTEGRATION TIME:

If you want to see how long it takes to achieve a certain noise level:

  ($time,$status) = int_time($noise,$filter,$mode,$nefd);

    or

  ($time,$status) = 
    int_time($noise,$filter,$mode,$nefd,$length,$width);

The first case is for jiggle mapping, photometry and polarimetry. The second 
is for scan mapping, where map dimensions must be specified. 

=head2 Parameters

=over

=item 1.

The first parameter is the desired noise level.

=item 2.

The second parameter is the filter wavelength in microns, which is one of 
'350','450','750','850','1350' or '2000'

=item 3.

The third parameter is the observation mode, which may be one of the following:

  'phot'  = photometry
  'jig16' = 16 point jiggle map
  'jig64' = 64 point jiggle map
  'scan'  = scan mapping 
  'pol'   = polarimetry

Scan mapping requires additional parameters. See 5th and 6th parameters.

=item 4.

The fourth parameter is the NEFD of SCUBA for a given atmospheric transmission
and filter wavelength. (see the function JCMT::SCUBA::scunefd).

=item 5. & 6.

If scan mapping, the last two parameters are the length and width of the map in
in arcseconds. Length in this case means in the direction of the scan.

=back

=head2 Return Values

int_time returns a 2-element list. The first element is the integration
time  in seconds. The second is a scalar containing the exit status of the 
function:

 status = 0: successful
         -1: failure due to invalid parameters
         -2: incorrect number of parameters

=cut

#------------------------------------------------------------------------------

sub int_time {

  my $noise = $_[0];
  my $filter = $_[1];
  my $mode = uc $_[2];
  my $nefd = $_[3];
  my ($length,$width,$status,$int);

  # Need map dimensions if scan mapping

  if ($mode eq 'SCAN') {

    # First see that we have the right # of parameters

    unless ($#_ == 5) {
      return (0,-2);
    }

    $length = $_[4];
    $width = $_[5];

    # now check dimensions

    unless ($length>0 && $width>0) {
      return (0,-1);
    }
  }

  # Otherwise we only need 4 parameters

  elsif ($#_ != 3) {
    return (0,-2);
  }

  # Make sure we have positive noise level

  unless ($noise > 0) {
    return (0,-1);
  }

  # Check NEFD value

  unless ($nefd > 0) {
    return (0,-1);
  }

  # Basic integration calculation

  $int = ($nefd/$noise)**2;

  # Now we have special factors for different modes:

 CASE: {

    # --- 1st Case ---  Photometry (no factor)

    if ($mode eq 'PHOT') {
      last CASE;
    }
	  
    # --- 2nd Case ---  Jiggle Mapping (factor of 16)

    if ($mode eq 'JIG16' || $mode eq 'JIG64') {
      $int *= 16;
      last CASE;
    }

    # --- 3rd Case --- Scan Map (depends on map size & array)
    
    if ($mode eq 'SCAN') {
	    
      # If map dimensions given are good...
	    
      $int *= (138+$length)*$width/9;
	      
      if ($filter eq '350' || $filter eq '450') {
	$int /= 91;
	last CASE;
      }
      elsif ($filter eq '750' || $filter eq '850') {
	$int /= (37*4);
	last CASE;
      }
    }
    
    # --- 4th Case --- Polarimetry 

    if ($mode eq 'POL') {
      $int *= 4.4;
      last CASE;
    }

    # Bad exit status if no matches
    
    return (0,-1);

  } # --- End of Case Statement ---

  return ($int,0);
}

#------------------------------------------------------------------------------

=head2 INTEGRATION TIME <=> INTEGRATIONS:

Here are a couple functions to go back and forth between a number of 
integrations, and integration time in seconds:

  $num_ints = time2int($time, $mode);
  $int_time = int2time($ints, $mode);

=head2 Parameters

=over

=item 1.

The first parameter in time2int is the integration time in seconds. In 
int2time, it is the number of integrations.

=item 2.

The second parameter is the mode, which is one of 'phot' for photometry, 
'jig16' for 16 point jiggle map and 'jig64' for 64 point jiggle map. 'scan' 
and 'pol' are not valid because integrations do not have any meaning in scan 
mapping or polarimetry.

=back

=head2 Return Values

time2int and int2time return a 2-element list. The first element is the 
number of integrations for time2int and integration time for int2time. The 
second is a scalar containing the exit status of the function:

 status = 0: successful
         -1: failure due to invalid parameters

=cut

#------------------------------------------------------------------------------

# Hash for storing integration times for each observation mode (in seconds):

my %mode_time = (
		 phot  => 18,
		 jig16 => 32,
		 jig64 => 128,
);

sub time2int ($$) {
  
  if (defined( $mode_time{$_[1]} ) && $_[0]>0 ) {
    my $thisint = sprintf("%lu",1+$_[0]/$mode_time{$_[1]});
    $thisint /= 1;
    return ($thisint,0);
  }

  else {
    return 0,-1;
  }
} 

sub int2time ($$) {

  if (defined( $mode_time{$_[1]} ) && $_[0]>0 ) {
    return ($_[0]*$mode_time{$_[1]},0);
  }

  else {
    return 0,-1;
  }
} 

#------------------------------------------------------------------------------
# End of PERL code and documentation footer.
#------------------------------------------------------------------------------
1;

=head1 NOTES

Although limited types of mapping may be performed with the photometry
pixels at 1350 and 2000 microns, this module will only support the
'phot' and 'pol' modes at these wavelengths at present.

It is likely that the transmission of the atmosphere is not known at any
given time. Usually CSO Tau is known however, so to derive the transmission
see JCMT::Tau::get_tau and JCMT::Tau::transmission.

Whenever 'noise' is referred to, it is the RMS noise level, which is normally
the (source-flux)/(sigma). In the case of polarimetry, is the polarised RMS 
noise level which includes the polarisation factor: 
(polarisation)(source-flux)/(sigma).

=head1 AUTHOR

Module created by Edward Chapin, echapin@jach.hawaii.edu
(with help from Tim Jenness, timj@jach.hawaii.edu)

=cut
