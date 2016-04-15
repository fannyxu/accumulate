#!/usr/local/bin/perl
##################################################################
# rsltAll.pl

# Paul Wei
##################################################################
use strict;
my $LAST_LINES=50000;
my $SEP = "\t";   # field separator
my $SEP = ",";   # field separator

if ($#ARGV<0) {
  print "Extract all results from 'sim_dir' and write to file 'sim_dir.out'. 
The simulation results are assumed to be in files 'out.txt'. Extract only last
$LAST_LINES lines from file.

syntax:
  ./rslt.pl sim_dir [sim_dir...]

";
  exit(0);
}

foreach my $dir (@ARGV) {
  ExtractDirResult($dir);
}

##################################################
# Extract Dir results
##################################################
sub ExtractDirResult {
  my $dir = shift;

  if (!-d $dir ) {
    print "Directory not found: $dir\n";
    exit(0);
  }

  my @Lst;
  getfiles(\@Lst, $dir);
  @Lst = grep {/out\.txt/} @Lst;

  my $outfile = "${dir}.out";
  open(FO,">$outfile");
  #select(FO);

  my $ln = "File,SNR,PER,Slots,NPass,NSent,Kpbs,FER,FNonlyRatio,EQonlyRatio,FnMRC,EqMRC,Nmiss,Nfalse\n";
  $ln =~ s/,/$SEP/g;
  print FO $ln;
  print    $ln;

  foreach my $fn (@Lst) {
    ExtractResult($fn);
  }
}


##################################################
# Extract file results
##################################################
sub ExtractResult {
  my $fn = shift;
  my $t = $fn;
  $t =~s/\/out.txt//;
  $t =~ s/\.\///;
  $t =~ s/\// /g;

  my $last;
  my $kpbs;
  my $per;
  my $eqr;
  my $fnr;
  my $rr;
  my $er;
  my $nm;
  my $nf;
    my $ln;
    if ($fn =~/\.zip/) {
      $ln = `unzip -p $fn|tail -$LAST_LINES`;
    } 
    elsif ($fn =~ /\.gz/ ) {
      $ln = `gunzip -c $fn|tail -$LAST_LINES`;
    }
    else {
      $ln = `tail -$LAST_LINES $fn`;
    }

    my @RSLT = split(/\n/, $ln);
    my $prev=100;
    for (my $i=0;$i<=$#RSLT;$i++) {
      $_ = $RSLT[$i];
      if (/ SNR=/) {
        my @F = split(/ +/);
        my $snr=$F[2];
        my $per=$F[6];
        my $slt=$F[8];
        my $pass=$F[10];
        my $sent=$F[12];
        $last = "$snr,$per,$slt,$pass,$sent";

  #      if ($prev!=100 && $prev!=$snr) {
  #.. SNR=   -10 dB :: PER=     -0 #AvgSlots= 1 PktsPassed= 0 PktsSent= -8 ; 
  #        print FO "$fn $last\n";
  #        print "$fn $last\n";
  #      }
        $prev = $snr;
      }
      elsif (/Throughput/) {
        s/.*=//;
        my @F = split(/[ \t]+/);
        $kpbs = $F[1];
        $per  = $F[2];
      }
      elsif (/EQratioMRC/) {
        s/.*=//;
        my @F = split(/[ \t]+/);
        $eqr =  $F[1];      
      }
      elsif (/FNratioMRC/) {
        s/.*=//;
        my @F = split(/[ \t]+/);
        $fnr =  $F[1];      
      }
      elsif (/FNonlyRatio/) {
        s/.*=//;
        my @F = split(/[ \t]+/);
        $rr =  $F[1];      
      }
      elsif (/EQonlyRatio/) {
        s/.*=//;
        my @F = split(/[ \t]+/);
        $er =  $F[1];      
      }
      elsif (/Preamble: Nmiss /) {
        #s/.*=//;
        my @F = split(/ +/);
        $nm =  $F[5];     
        $nf =  $F[9]; 
      }
      
    }

    my $ln = "$fn,$last,$kpbs,$per,$rr,$er,$fnr,$eqr,$nm,$nf\n";
    $ln =~ s/,/$SEP/g;
    print FO $ln;
    print    $ln;
    $last=0; $kpbs=0; $per=0;$eqr=0; $fnr=0; $rr=0;$er=0;$nm=0;$nf=0;
}

##################################################
# get all files in directory 
# param: \@Files  - array of files (output)
#        Dir      - directory name
#        Cnt      - directory level
##################################################
sub getfiles{
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
            getfiles($Files_ref, $full, $cnt);
        }
        else {
            push(@$Files_ref, $full);
        }
    }
}
