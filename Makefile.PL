use ExtUtils::MakeMaker;
WriteMakefile(
  'NAME'         => 'JCMT::SCUBA',
  'VERSION_FROM' => 'SCUBA.pm',
  'dist'         => { COMPRESS => "gzip -9f" }
  ); 
