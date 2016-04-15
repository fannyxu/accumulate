package Sim;
use strict;
use Cwd;

##########################################################################
# simulation setup
##########################################################################
our %SIM = (
# configuration
  TOP_DIR       => 'top_dir',   # simulation dir
  TOP_SRP       => 'go.sh',     # start simulation script
  STOP_SRP      => 'stop.sh',   # stop simulation script
  SIM_NUM       => 0,           # start simulation number 
  PARM_FN       => 'parm.m',    # simulation parm name
  EXEC          => '{CWD}/Build/release/testbench',   # executable {CWD} = current dir
  ARGS          => 'test 0',    # arguments after parm file
  BEFORE_SIM_CMD => '',         #
  AFTER_SIM_CMD => 'zip -m hex *.hex; gzip out.txt',  #
  QSUB_OPT      => '',          # qsub options '-l short', '-l low'
  BACKUP_SRC    => 1,           # 1=enable backup of source

# local variables
  PARM_FN_BASE  => 'parm',      # simulation parm base name
  CWD           => '',          # current dir
  FULL_PARM_FN  => '',          # parameter file name
);

#########################################################################################
# Support Functions
#########################################################################################

##################################################
# generate script for simulation
#   param: \@Parm - parameter array
#
#   return: script name
##################################################
sub GenScript {
    my $Parm   = shift; # ref @
    my $disp   = shift;
    $SIM{SIM_NUM}++;

    #############################
    # create sim dir
    if (! -e $SIM{TOP_DIR}) { mkdir $SIM{TOP_DIR}; }

    my $fnb = $SIM{PARM_FN};
    $fnb =~ s/.*\///;           # remove path
    $fnb =~ s/\..*//;           # remove extension
    $SIM{PARM_FN_BASE} = $fnb;

    my $simdir = sprintf('%02d_%s', $SIM{SIM_NUM}, $SIM{PARM_FN_BASE});
    print "############### GenScript ", $simdir,"\n", if ($disp);

    mkdir "$SIM{TOP_DIR}/${simdir}";

    #############################
    # write sim parm file
    $SIM{FULL_PARM_FN} = "$SIM{TOP_DIR}/${simdir}/$SIM{PARM_FN_BASE}.m";
    my $parm   = join("\n", (@$Parm));

    open(FO,">$SIM{FULL_PARM_FN}") || die "$! : $SIM{FULL_PARM_FN}\n";
    print FO $parm,"\n";
    close(FO);

    #############################
    # write sge sim script file
    #my $script = "$SIM{TOP_DIR}/${simdir}/$SIM{PARM_FN_BASE}.sh";
    my $script = sprintf("$SIM{TOP_DIR}/${simdir}/$SIM{TOP_DIR}_%02d.sh", $SIM{SIM_NUM});

    if ($SIM{TOP_DIR} =~ /^(\d+)/) { #script cannot begin w/ number
        my $sim_num=$1;
        $script = sprintf("$SIM{TOP_DIR}/${simdir}/t%02d_%02d.sh", $sim_num, $SIM{SIM_NUM});
    }


    open(FO,">${script}");

    my $exec = $SIM{EXEC};
    $exec =~ s/.*\///;
    $exec = "../$exec";

    print FO "#
cd $SIM{CWD}/$SIM{TOP_DIR}/${simdir}
hostname > host.txt
$SIM{BEFORE_SIM_CMD}
$exec $SIM{PARM_FN_BASE}.m $SIM{ARGS} > out.txt
$SIM{AFTER_SIM_CMD}
";
    close(FO);

    #############################
    # write TOP script
    my $out = "qsub $SIM{QSUB_OPT} ${script} | awk '{print \"qdel \" \$3 \" # \" \$4 }'| tee -a $SIM{TOP_DIR}/$SIM{STOP_SRP}\n";
    WriteTopSimScript($out);

    return(${script});
}

##################################################
# Initialize simulation directory
##################################################
sub Init {
  my $sim_top = shift;
  $sim_top =~ s/\..*//; # remove extension

  $SIM{CWD} = getcwd;
  $SIM{EXEC} =~ s/{CWD}/$SIM{CWD}/;

  $SIM{TOP_DIR} = $sim_top;
  if (! -e $sim_top) { mkdir $sim_top; }

  my $sim_top_full = "$SIM{CWD}/$sim_top";

  my $v_sge_script = "$SIM{TOP_DIR}/$SIM{TOP_SRP}";
  unlink $v_sge_script;

  open(Fscript, ">>${v_sge_script}") || die "$! : $v_sge_script";

print Fscript "
echo Copy executable to $SIM{TOP_DIR}/
cp $SIM{EXEC} $SIM{TOP_DIR}
";

if ($SIM{BACKUP_SRC}) {
  print Fscript "
echo Backing up source to $SIM{TOP_DIR}/$SIM{TOP_DIR}_source.zip
(cd ../..; zip -q -r $SIM{CWD}/$SIM{TOP_DIR}/$SIM{TOP_DIR}_source blocks* ${sim_top_full}  -i \"*.cpp\" -i \"*.h\" -i \"*.m\" -i \"*.pl\" -i\"Makefile\" -i\"*.inc\" -i\"*.out\" -i\"*.sh\")
  ";
  }
}


##################################################
# ListDirFiles( dirnm)
# returns a reference to array of files
# in the directyr
##################################################
sub  ListDirFiles {
  my $top = $_[0];
  my $rf= $_[1];
  if ($rf==0) { $rf = \@SIM::Files; 
    $#{$rf} = -1; # clear array  
  }

  opendir(D,$top);
  my @D = readdir(D);
  closedir(D);
  foreach my $i (@D) {
    my $fn ="$top/$i"; 
    if ($fn !~ /\/[.]+$/) {
      if (-d $fn) {
         ListDirFiles($fn,$rf);
      } else {
        push(@$rf, $fn);
      }
    }
  }
  return($rf);
}

##################################################
# get files array
##################################################
sub GetFilesA {
  my $rF = shift;
  my $rA = shift;
  foreach my $arg (@$rA) {
      $arg =~ s/\/$//;
      if (-d $arg) {
        Sim::GetFiles($rF, $arg);    
      } else {
        push(@$rF, $arg);
      }
  }
}

##################################################
# get all files in directory 
# param: \@Files  - array of files (output)
#        Dir      - directory name
#        Cnt      - directory level
##################################################
sub GetFiles{
    my $Files_ref= shift;
    my $dir = shift;
    my $cnt = shift;
    my $D; opendir($D, $dir);
    my @files = grep {/[\da-z]/i} readdir($D);
    closedir($D);
    $cnt++ ;
    foreach my $i (@files) {
        my $full = "$dir/$i";
        if (-d $full ) {
            GetFiles($Files_ref, $full, $cnt);
        } else {
            push(@$Files_ref, $full);
        }
    }
}

##################################################
# get all files in directory for not greater than $Limit_Cnt
# param: \@Files  - array of files (output)
#        Dir      - directory name
#        Limit_Cnt - limit dictionary level
#        Cnt      - directory level
##################################################
sub GetFilesL{
    my $Files_ref= shift;
    my $dir = shift;
    my $limit_cnt = shift;
    my $cnt = shift;
    my $D; opendir($D, $dir);
    my @files = grep {/[\da-z]/i} readdir($D);
    closedir($D);
    $cnt++ ;
    unless($cnt>$limit_cnt){
    foreach my $i (@files) {
        my $full = "$dir/$i";
        if (-d $full ) {
            GetFilesL($Files_ref, $full, $limit_cnt,$cnt);
        } else {
            push(@$Files_ref, $full);
        }
    }
}
}
##################################################
# read parameter file into array
#   Concat arrays into one line
#
# param: filename   - parameter file name
#        [\@Array]  - lines from file in array form
# 
##################################################
sub ReadParmFile {
  my $fn = shift;
  my $ary_ref= shift;
  if ($ary_ref==0) { $ary_ref = \@SIM::Param; 
    $#{$ary_ref} = -1; # clear the array
  }

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
  return(@{$ary_ref});
}

##################################################
# extract one line array from string
# param:  str - string with array
# return: array of values enclosed in [ ]
##################################################
sub ExArray {
  my $str = shift;  # string w/ array
  $str =~ s/\n/ /;
  $str =~ s/.*?=//; 
  $str =~ s/.*\[//;
  $str =~ s/ *\].*//;
  $str =~ s/^ +//;
  $str =~ s/[ \t]+/ /;
  $str =~ s/;/ /g;
  return( split(/[ \t]+/, $str) );
}

##################################################
# get first occurance of 'str' in parameter array
# param: \@parm
#         str
# return: string
##################################################
sub GetParm {
  my $parm = shift;    # ref @parm
  my $str  = shift;    # string

  my $found=0;
  my $line=0;
  my $ln = "";
  for (my $i=0;$i<=$#$parm;$i++) {
    #if ($$parm[$i] =~ /^[^%]*$str[ =]/) {   # find start of array
    if ($$parm[$i] =~ /^$str[ =]/) {   # find start of array
      $ln = $$parm[$i];
      $ln =~ s/\%.*//;
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

##################################################
# get first occurance of 'str' array from parameter
# param: \@parm - parameter array
#         str
# return: array
##################################################
sub GetParmArray {
  my $parm = shift;  # ref @param
  my $str  = shift;  # name string
  my $ln = GetParm($parm, $str);
  return( ExArray($ln) );
}

##################################################
# replace all occurances of a parameter with another
# param: \@param - parameter array
#        $str    - in form 'name = value'
##################################################
sub ReplaceParm {
  my $parm = shift;    # reference to array of string
  my $str  = shift;    # string
  my $disp = shift;

  my @strM = split(/\n/,$str);
  foreach $str (@strM) {
    if ($str!~/^ *$/ && $str !~/^ *%/) {
      $str =~ /(.*?)=(.*)/;
      my $nm = $1;
      my $val = $2;
      $nm =~s/^ +//;  $nm =~s/ +$//;
      $val =~s/^ +//; $val =~s/ +$//;

      print "$nm = $val\n", if ($disp);
      my $nms = $nm;
      $nms =~ s/([\[\]\\\/])/\\$1/g;
      my $found=0;
      for (my $i=0;$i<=$#$parm;$i++) {
         $_ =~ s/^\s+//;
         if ($$parm[$i]!~/^ *%/ &&        # ignore comment
             $$parm[$i]=~/^${nms}[ =]/)    # match name
         {
            $$parm[$i] = "$nm = $val  %ORIG: $$parm[$i]";
            $found=1;

           # remove continuation
           if ($$parm[$i]=~/\.\.\.[ \t]*$/) { 
             my @del;
             do {
               push(@del, $i+1); $i=$i+1;
             } while ($$parm[$i]=~/\.\.\.[ \t]*$/);

             foreach my $kk (@del) { $$parm[$kk] = ""; }
           }
         }
#         elsif ($$parm[$i]!~/^ *%/ &&      # ignore comment
#             $$parm[$i]=~/${nms}[ =]/i)    # match name w/ different case
#         {
#            print "Warning: Similar match for ( $nm ) --> $$parm[$i]\n";
#         }
        
      } #for
      if ($found==0) {
        push(@$parm, "$nm = $val; %NEW:");
      }
    }
  }
  return($parm);
}

##################################################
# write line to top level simulation scipt
##################################################
sub WriteTopSimScript {
    my $ln = shift;
    open(Fscript,">>$SIM{TOP_DIR}/$SIM{TOP_SRP}");
    print Fscript $ln;
    close(Fscript);
}

##################################################
# generate simulation from table
# param: $parmfile = string: parameter file
#        $sims     = table string: line1=fields, line2,3....: parameters for each test
#                    all fields are delimited by spaces
#        $global   = string of global variable changes
##################################################
sub GenScriptTable {
    my $parmfile  = shift;
    my $sims = shift;
    my $global = shift;
    ###################################################################
    my @F = split(/\n/,$sims);
    my @simsM;
    for (my $i=0;$i<=$#F;$i++) {
      my $ln = $F[$i];
      $ln =~ s/^ +//;
      if ($ln =~ /[a-z\d]/i) {
        push(@simsM, $ln);
      }
    }

    ###################################################################
    my $out = "\n";
    for (my $i=0;$i<=$#simsM;$i++) {
      $out .= sprintf("# %3d %s\n", $i, $simsM[$i]);
    }
    print $out;
    WriteTopSimScript($out);

    ###################################################################
    # first line is label
    my @varnm = split(/[ \t]+/,$simsM[0]);

    # generate simulation scripts
    my @ParmOrg = Sim::ReadParmFile($parmfile);
    foreach my $sim (@simsM[1..$#simsM]) {
    #  print join(/ /,@varnm),"\n";
    #  print $sim,"\n";
      my @val = split(/ +/, $sim);
      my $sim_str = "";
      for (my $j=0;$j<=$#val;$j++) {
          $sim_str .= sprintf("%20s = %s\n", $varnm[$j], $val[$j]);
    #      printf("%20s = %s\n", $varnm[$j], $val[$j]);
      }
      my @Parm = @ParmOrg;
      Sim::ReplaceParm(\@Parm, "
          $global 
          $sim_str
      ");
      Sim::GenScript(\@Parm);
    }
}

1;
