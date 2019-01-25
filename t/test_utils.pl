# DESCRIPTION: Perl ExtUtils: Common routines required by package tests
#
# Copyright 2000-2019 by Wilson Snyder.  This program is free software;
# you can redistribute it and/or modify it under the terms of either the GNU
# Lesser General Public License Version 3 or the Perl Artistic License Version 2.0.

use IO::File;
use File::Copy;
use strict;
use vars qw($PERL);

$PERL = "$^X -Iblib/arch -Iblib/lib -IPreproc/blib/arch -IPreproc/blib/lib";

mkdir 'test_dir',0777;
unlink "test_dir/verilog";   # Symlink made in vpassert test will mess up others

if (!$ENV{HARNESS_ACTIVE}) {
    use lib '.';
    use lib '..';
    use lib "blib/lib";
    use lib "blib/arch";
    use lib "Preproc/blib/lib";
    use lib "Preproc/blib/arch";
}

sub run_system {
    # Run a system command, check errors
    my $command = shift;
    print "\t$command\n";
    system "$command";
    my $status = $?;
    ($status == 0) or die "%Error: Command Failed $command, $status, stopped";
}

sub run_system_no_die {
    # Run a system command, check errors
    my $command = shift;
    print "\t$command\n";
    system "$command";
    return $?;
}

sub wholefile {
    my $file = shift;
    my $fh = IO::File->new ($file) or die "%Error: $! $file";
    my $wholefile = join('',$fh->getlines());
    $fh->close();
    return $wholefile;
}

sub files_identical {
    my $fn1 = shift;	# got
    my $fn2 = shift;	# expected
    my $f1 = IO::File->new ($fn1) or die "%Error: $! $fn1,";
    my $f2 = IO::File->new ($fn2) or die "%Error: $! $fn2,";
    my @l1 = $f1->getlines();
    my @l2 = $f2->getlines();
    my $nl = $#l1;  $nl = $#l2 if ($#l2 > $nl);
    for (my $l=0; $l<=$nl; $l++) {
	$l1[$l] =~ s/\r\n/\n/g if defined $l1[$l];  # Cleanup if on Windows
	$l2[$l] =~ s/\r\n/\n/g if defined $l2[$l];
	if (($l1[$l]||"") ne ($l2[$l]||"")) {
	    next if ($l1[$l]||"") =~ /Generated by vrename on/;
	    warn ("%Warning: Line ".($l+1)." mismatches; $fn1 $fn2\n"
		  ."GOT: ".($l1[$l]||"*EOF*\n")
		  ."EXP: ".($l2[$l]||"*EOF*\n"));
	    if ($ENV{HARNESS_UPDATE_GOLDEN}) {  # Update golden files with current
		warn "%Warning: HARNESS_UPDATE_GOLDEN set: cp $fn1 $fn2\n";
		copy($fn1,$fn2);
	    } else {
		warn "To update reference: HARNESS_UPDATE_GOLDEN=1 ".join(" ",$0,@ARGV)."\n";
	    }
	    return 0;
	}
    }
    return 1;
}

sub get_memory_usage {
    # Return memory usage.  Return 0 if the system doesn't look quite right.
    my $fh = IO::File->new("</proc/self/statm");
    return 0 if !$fh;

    my $stat = $fh->getline || "";
    my @stats = split /\s+/, $stat;
    return ($stats[0]||0)*4096;  # vmsize
}

1;
