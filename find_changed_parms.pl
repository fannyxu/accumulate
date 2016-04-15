#!/usr/bin/perl
use Cwd;
use strict;
my $DBG = 0;

# field separator (should be unique character)
my $SEP = "\t";  # field separator
my $SEP = ",";  # field separator

if ($#ARGV<0) {
  print "Find all changed simulation parameters:

  syntax: perl find_changed_parms.pl sim_dir [sim_dir2] [sim_dir3]...\n
";
  exit(0);
}

my $cwd = getcwd;
#print "cwd: $cwd\n";

foreach my $dir (@ARGV) {
    $dir =~ s/\..*//;
    parse($dir);
}


############################
my $result_header;
my %RESULT;   # simulation results
my %dbParm0;  # baseline parameter (first file)
my %dbDiff;   # parameters that are different
my %SimParm;  # simulation param, dir:string of param values

############################
# read all directories
sub parse { #{{{
    my $dir = shift;
    opendir(D, $dir);
    my @dbDir = grep { /[a-z]/i } readdir(D);
    closedir(D);

#print "dir: $dir\n";
    # read output file if available
    my $have_outfile = 0;

    my $outfile = "$cwd/${dir}.out";
    if (-e $outfile ) { $have_outfile=1; }
    #print "$outfile\n";

    if ($have_outfile==0) {
        $outfile = "${dir}.out";
        if (-e $outfile ) { $have_outfile=1; }
    }
    #print "$outfile\n";

    if ($have_outfile) {
      print "read $outfile file\n", if ($DBG);
      open(FP, $outfile);
      if (length($result_header)<1) {
        $result_header=<FP>;  # first line
        $result_header=~s/^[^${SEP}]+${SEP}//;  # remove fist element
        chomp($result_header);
      }

      my $fb = $outfile;
      $fb =~ s/\/[^\/]+$//;  # remove file name

      while(<FP>) {
        chomp;
        my @F = split(/$SEP/);
        my $nm = shift(@F);
        my $rslt = join($SEP, @F);
        $nm =~ s/\/[^\/]+$//;  # remove file name
        $nm = "${fb}/$nm";
        $RESULT{$nm} = $rslt;
        print "$nm  => $rslt\n", if ($DBG);
      }
      close(FP);
    }

    # read parameter file
    # and save differences
    for (my $i=0;$i<=$#dbDir;$i++) {
      my $fn = $dbDir[$i];
      if (-d "$dir/$fn") {
        opendir(D, "$dir/$fn") || die "$dir/$fn";
        print "File: $fn ============================================================\n", if ($DBG);
        my @F =  grep { /\.m$/ } readdir(D);
        my $fn = "$dir/$fn/$F[0]";
        print $fn,"\n", if ($DBG);
        if ($#F >= 0) {
          my $done = scalar keys %dbParm0;
          if ($done==0) {  # save baseline
            %dbParm0 = ();  # clear 
            my @T;
            ReadParmFile($fn, \@T );
            foreach my $i (sort @T) {
               if ($i =~ /(.*?)=(.*)/) {
                 my $nm = $1; my $val = $2;
                 $nm =~ s/ //;
                 $val =~ s/;/ /g;
                 $val =~ s/[ \t] +/ /g;
                 $val =~ s/^ //g;
                 $val =~ s/ $//g;
                 $dbParm0{$nm} = $val;
                 print "dbParm0:  $nm  : $val\n", if ($DBG);
               }
            }
          } else {
            my %dbParm = ();  # clear 
            my @T;
            ReadParmFile($fn, \@T );
            foreach my $i (sort @T) {
               if ($i =~ /(.*?)=(.*)/) {
                 my $nm = $1; my $val = $2;
                 $nm =~ s/ //;
                 $val =~ s/;/ /g;
                 $val =~ s/[ \t] +/ /g;
                 $val =~ s/^ //g;
                 $val =~ s/ $//g;
                 $dbParm{$nm} = $val;
               }
            }

            foreach my $i (sort keys %dbParm0) {
              if (!exists($dbParm{$i})) { $dbParm{$i}="NA";}
              if ($dbParm0{$i} != $dbParm{$i}) 
              {
                print "================= $i  $dbParm0{$i}  :: $dbParm{$i}\n", if ($DBG);
                $dbDiff{$i} = 1;
              }
              if ($dbParm0{$i} ne $dbParm{$i}) {
                print "================= $i  $dbParm0{$i}  :: $dbParm{$i}\n", if ($DBG);
                $dbDiff{$i} = 1;
              }
            }

            foreach my $i (sort keys %dbParm) {
              if (!exists($dbParm0{$i})) { $dbParm0{$i}="NA";}
              if ($dbParm0{$i} != $dbParm{$i}) 
              {
                print "================= $i  $dbParm0{$i}  :: $dbParm{$i}\n", if ($DBG);
                $dbDiff{$i} = 1;
              }
              if ($dbParm0{$i} ne $dbParm{$i}) {
                print "================= $i  $dbParm0{$i}  :: $dbParm{$i}\n", if ($DBG);
                $dbDiff{$i} = 1;
              }
            }
          }
        }
        closedir(D);
      }
    }
} # end parse
#}}}

##############################################
#
# print parameter differences
#
#foreach my $i (sort keys %dbDiff) {
#  print $i,"\n";
#}
#print "\n";

##############################################
# get changed variables
my @VAR = sort keys %dbDiff;

#
# find all parameters
#
foreach my $dir (@ARGV) {
opendir(D,$dir);
my @D = readdir(D);
closedir(D);
foreach my $i (@D) {
 #print "*********** Dir $i\n",if($DBG);
  if ( $i =~ /[a-z]/ && -d "$dir/$i" ) {
 print "*********** Dir $i\n",if($DBG);
    GenSimParam("$dir/$i", \@VAR, \%SimParm);
  }
}
}

##############################################
# print table to stdio
print "ARGV ",$#ARGV,"\n", if ($DBG);
if ($#ARGV==0) {
    my $dir = $ARGV[0];
    my $fn_out= $dir;

    if ($SEP eq ",") {
        $fn_out .= ".csv";
    } 
    elsif ($SEP eq "\t") {
        $fn_out .= ".tab";
    } 
    else {
        $fn_out .= ".out1";
    }

    open(FO,">$fn_out");

} else {
  my $fn = "find_changed_parms.csv";
    unlink $fn;
    open(FO,">$fn");
}

{ 
  print "Sim${SEP}File${SEP}", join($SEP, @VAR),"${SEP}$result_header\n";
  print FO "Sim${SEP}File${SEP}", join($SEP, @VAR),"${SEP}$result_header\n";
  my @SZ;
  my $nmsz=0;
  # find largest number of characters for each parameter
  #foreach my $i (keys %SimParm) {
  #  if ($nmsz < length($i)) { $nmsz = length($i); };
  #  my @F = split(/ /,$SimParm{$i});
  #  for (my $i=0;$i<=$#F;$i++) {
  #    my $sz = length($F[$i]);
  #    if ($SZ[$i] < $sz) { $SZ[$i] = $sz; };
  #  }
  #}

  my %ShortNmMap;
 
  my $k = 0;
  my %AdjustParm;
  foreach my $nm(keys %SimParm)
  {
     if($nm =~ /(.*)\/([\d]+)_(.*)$/)
       {
         $AdjustParm{$2} = $nm;
         if($DBG){print $nm," ",$2,"\n"};
         $k++;
       }
  } 
  print "$k\n",if($DBG);
  my @Num = keys %AdjustParm;
  my @AdjustNum = sort {$a<=>$b} @Num;
  
  my @Nm;
  $k=0;
  foreach my $nm(@AdjustNum)
 {
   $Nm[$k] = $AdjustParm{$nm};
   $k++;
 }
  print "$k\n",if($DBG);

 # my @Nm = sort keys %SimParm

  my $minlen = 1e8;
  foreach my $k (@Nm) {
    if (length($k) < $minlen) { $minlen = length($k); }
  }

  my $match = 0;
  loop: for (my $c=0;$c<$minlen;$c++) {
    my $ch = substr($Nm[0], $c, 1);
    for (my $i=1;$i<=$#Nm;$i++) {
        if (substr($Nm[$i], $c, 1) != $ch) { $match = $c-1; last loop; }
    }
  }
  #print "match: $match\n";
  
  foreach my $k (@Nm) {
    $ShortNmMap{$k} = substr($k,$match);
  }

  #foreach my $nm (sort keys %SimParm) {
  foreach my $nm (@Nm) {
    print "dir --> $nm \n", if ($DBG);
#    printf("%-${nmsz}s ", $nm);
#    printf(FO "%-${nmsz}s ", $nm);
    my @F = split(/\//,$nm);
    my $h1 = $F[$#F-1]."/".$F[$#F];
    my $h2 = $ShortNmMap{$nm};

    printf("%s${SEP}%s${SEP}",$h1,$h2);
    printf(FO "%s${SEP}%s${SEP}",$h1,$h2);
    #my @F = split(/ /,$SimParm{$nm});
    #my $out = "";
    #for (my $i=0;$i<=$#F;$i++) {
    #  $out .= sprintf("%$SZ[$i]s ", $F[$i]); 
    #  out .= sprintf("%s,", $F[$i]); 
    #}
    my $out = $SimParm{$nm};
    $SimParm{$nm} = $out;
    print "$out ";
    print $RESULT{$nm};
    print "\n";
    print FO "$out ";
    print FO $RESULT{$nm};
    print FO "\n";
  }
}

####################################################
sub GenSimParam { #{{{
  my $dirnm = shift;        # parameter filename
  my $var_ref = shift;   # change variables
  my $parm_ref = shift;  # all parameters

  if (-e "$cwd/$dirnm") { $dirnm = "$cwd/$dirnm"; }

  opendir(D, $dirnm);
  my @D = grep { /\.m$/ } readdir(D);
  my $fn = "$dirnm/$D[0]";

  my @Parm; 
  ReadParmFile($fn, \@Parm);

  my @F; 
  my $out = "";

  foreach my $i (@$var_ref) {
    if ($i =~ /[^ ]/) {
#    print GetParm(\@Parm, $i),"\n";
        @F = GetParmArray(\@Parm, $i);
        if ($#F<0) {
          $out .= "NA${SEP}";
          #print "xxx3 $i : $out\n";
        } 
        elsif ($#F==0) {
          $out .= "$F[0]${SEP}";
          #print "xxx2 $i : $out\n";
        }
        else {
          my $t = join(' ',@F);
          $out .= "\"[$t]\"$SEP";
          #print "xxx1 $i : $out\n";
        }
    }
  }
  #@F = split(/\//,$dirnm);
  $$parm_ref{$dirnm} = $out;
}
#}}}

#############################################
# Concat arrays into one line
# 
sub ReadParmFile { #{{{
  my $fn = shift;
  my $ary_ref= shift;

  open(FP, $fn); 
  my $ln = "";
  while(<FP>) {
    chomp;
    s/^[ \t]*//;
    s/\%.*//;
    s/[ \t]+$//;
    if (length($_) > 0) {
      $ln = "$ln$_";
      if ($ln !~ /\.\.\./) {
        if (length($ln)>0) {
          $ln =~ s///g;
          # split out mutltiple definitions in a line
          while($ln =~ /(^[^=]+=[^=]+?)[^ ;]+ *=/) {
              push(@$ary_ref, $1);
              $ln = substr($ln,length($1));
          }
          if ($ln =~ /=/) {
              push(@$ary_ref, $ln);
          }
        }
        $ln = "";
      } else {
        # line contain '...' get next line
        $ln =~ s/\.\.\.//;
      }
    }
  }
  close(FP);
}
#}}}

##################################################
# get first occurance of 'str' array from parameter
# param: \@parm - parameter array
#         str
# return: array
##################################################
sub GetParmArray { #{{{
  my $parm = shift;  # ref @param
  my $str  = shift;  # name string
  my $ln = GetParm($parm, $str);
  return( ExArray($ln) );
}
#}}}


##################################################
# get first occurance of 'str' in parameter array
# param: \@parm
#         str
# return: string
##################################################
sub GetParm { #{{{
  my $parm = shift;    # ref @parm
  my $str  = shift;    # string

  my $found=0;
  my $line=0;
  my $ln = "";
  for (my $i=0;$i<=$#$parm;$i++) {
    #if ($$parm[$i] =~ /^[^%]*$str[ =]/) {   # find start of array
    if ($$parm[$i] =~ /^$str[ =]/) {   # find start of array
      $ln = $$parm[$i];
      if ($$parm[$i] =~ /\[/) { # array
        loop: for (my $j=0;$j<40;$j++) {
          if ($$parm[$i+$j] =~ /\]/) { $found=1; $line=$j;  last loop; }
        }
        if ($found) {
          for (my $j=1;$j<=$line;$j++) {
            $ln .= "\n" . $$parm[$i+$j];
          }
        } else {
          print "Array error: (line: $i)\n $$parm[$i]\n";
        }
      }
    }
  }
  return($ln);
}
#}}}

##################################################
# extract one line array from string
# param:  str - string with array
# return: array of values enclosed in [ ]
##################################################
sub ExArray { #{{{
  my $str = shift;  # string w/ array
  $str =~ s/\n/ /;
  $str =~ s/.*?=//; 
  $str =~ s/.*\[//;
  $str =~ s/ *\].*//;
  $str =~ s/^ +//;
  $str =~ s/[ \t]+/ /;
  $str =~ s/;/ /g;
  return( split(/[, \t]+/, $str) );
}
#}}}
