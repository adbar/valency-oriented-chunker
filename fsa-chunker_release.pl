#!/usr/bin/perl
use strict;
use warnings;


## This proof of concept was adapted from a full-fledged toolchain, it are not used in production as such. For demonstration purposes only.
## It could be optimized and/or run in another language as well.
## Copyright Adrien Barbaresi, ENS Lyon, 2011.


##### INIT

# $printv is the valency value output, $vpass shows if a verb has been seen or not.
my ($end_of_sentence, $state, $valency, $printv, $vpass, $s);

# sentence elements
my ($group, @tempgroup, $verb, @tempvpass);

# expects tab-separated output of the TreeTagger 
my @line = split("\t", $_);

# drop sentence boundary detection here:
if ($end_of_sentence == 1) {
    $state = ();
    $valency = 0; $printv = (); $vpass = 0;
    $s++;
}


### FSA PARSER
{no warnings 'uninitialized';

    # state transitions
    if ($group =~ m/GP0/) {
        if ( ($line[1] eq "ART") || ($line[1] eq "PPOSAT") || ($line[1] eq "PDAT") || ($line[1] eq "CARD") || ($line[1] eq "PIAT") || ($line[1] =~ m/ADJ/) || ($line[1] eq "ADV") ) {
            $group =~ s/0/1/;
        }
        elsif ( ($line[1] eq "NN") || ($line[1] eq "NE") ) {
            $group =~ s/0/3/;
        }
        elsif ( ($line[1] eq "PRF") || ($line[1] eq "PPER") || ($line[1] eq "PRELS") || ($line[1] eq "PIS") ) {
            $group =~ s/0/4/;
        }
        else {$group = () ;}
    }
    elsif ($group =~ m/GN0/) {
        if ( ($line[1] eq "PPOSAT") || ($line[1] eq "PDAT") || ($line[1] eq "CARD") || ($line[1] eq "PIAT") || ($line[1] =~ m/ADJ/) || ($line[1] eq "ADV") ) {
        $group =~ s/0/1/;
            }
        elsif ( ($line[1] eq "NN") || ($line[1] eq "NE") ) {
            $group =~ s/0/3/;
        }
        elsif ( $line[1] eq "PIS" ) {
            $group =~ s/0/4/;
        }
        else {$group = () ;}
        }
    elsif ($group =~ m/G.[1-2]/) {
        if ( ($line[1] eq "CARD") || ($line[1] eq "ADV") || ($line[1] eq "KON") || ($line[1] eq "PIAT") || ($line[1] =~ m/ADJ/) || ($line[1] eq "PIS") ) {
            $group =~ s/1/2/;
            }
        elsif ($line[1] eq "\$,") {
            $group .= "-KOM";
        }
        elsif ( ($line[1] eq "NN") || ($line[1] eq "NE") ) {
            $group =~ s/[1-2]/3/;
        }
        elsif ( $line[1] eq "APPR" ) {
            $group =~ s/[1-2]/0-P/;
        }
         elsif ($line[1] eq "APPRART" ) {
            $group =~ s/[1-2]/1-P/;
        }
        else {$group = () ;}
        }
    elsif ($group =~ m/G.3/) {
        if ( ($line[1] eq "ART") || ($line[1] eq "PPOSAT") || ($line[1] eq "PDAT") || ($line[1] eq "CARD") || ($line[1] eq "PIAT") || ($line[1] =~ m/ADJA/) ) {
            $group =~ s/3/1-P/;
            }
        elsif ( ($line[1] eq "NN") || ($line[1] eq "NE") ) {
            $group .= "-B";
            }
        elsif ($line[1] eq "KON") {
            $group .= "-KON";
            }
        elsif ( $line[1] eq "APPR" ) {
            $group =~ s/.3/P0-P/;
            }
        elsif ($line[1] eq "APPRART" ) {
            $group =~ s/.3/P1-P/;
            }
        else {$group = () ;}
        }
    elsif ($group =~ m/G.4/) {
        $group = () ;
    }

    # start of detection
    unless (defined $group) {
        if ( $line[1] eq "APPR" ) {
            $group = "GP0";
        }
        elsif ( $line[1] eq "APPRART" ) {
            $group = "GP1";
        }
        elsif ( ($line[1] eq "ART") || ($line[1] eq "PPOSAT") || ($line[1] eq "PDAT") || ($line[1] eq "CARD") || ($line[1] eq "PIAT") || ($line[1] =~ m/ADJA/) ) {
        $group = "GN0";
        }
        elsif ( ($line[1] eq "NN") || ($line[1] eq "NE") ) {
            $group = "GN3";
        }
        ### COUNT
        if ($group =~ m/N/) {
            push (@tempgroup, "1");
        }
        elsif ($group =~ m/P/) {
            push (@tempgroup, "2");
        }
    }
    else {
        if ($group =~ m/N/) {
            if (sum(@tempgroup)/scalar(@tempgroup) == 1) {
                push (@tempgroup, "1");
            }
            else {@tempgroup = (); push (@tempgroup, "1");}
        }
        elsif ($group =~ m/P/) {
            if (sum(@tempgroup)/scalar(@tempgroup) == 2) {
                push (@tempgroup, "2");
            }
            else {@tempgroup = (); push (@tempgroup, "2");}
        }
    }

    # analysis of verb phrases
    if (defined $state) {
        if ( $line[1] =~ m/V.FIN/ ) {
            unless ($state =~ m/3/) {$state =~ s/[0-3]/2/;}
            $verb = $state;
        }
        elsif ( ($line[1] =~ m/V.INF/) || ($line[1] =~ m/V.PP/) ) {
            if ($state =~ m/END/) {$state =~ s/[0-3]/3/;}
            else {$state =~ s/[0-3]/2/;}
            $verb = $state;
        }
        elsif ( $line[1] eq "VVIZU" ) {
            $state =~ s/[0-3]/3/;
            $verb = $state;
        }
        elsif ( ($line[1] eq "PPER") || ($line[1] eq "PDS") || ($line[1] eq "PRF") || ($line[1] eq "PRELS") || ($line[1] eq "PIS") || ($line[1] eq "PWS") ) {
            unless (defined $group) {
            $state =~ s/[0-3]/1/;
            $verb = $state;
            }
        }
        elsif ( ($line[1] =~ m/ADJ./) || ($line[1] eq "ADV") ) {
            unless (defined $group) {
            $state =~ s/[0-3]/1/;
            $verb = $state;
            }
            else {$verb = ();}
        }
        elsif ( ($line[1] =~ m/KOU./) || ($line[1] eq "PRELS") || ($line[1] =~ m/PWA/) || ($line[1] eq "PAV") ) {
            $state = "GV0-END";
            $verb = $state;
        }
        elsif ( $line[1] eq "KON" ) {
            unless (defined $group) {
            $state .= "-K";
            $verb = $state;
            }
        }
        elsif ( $line[1] eq "PTKNEG") {
        $state .= "-NEG";
        $verb = $state;
        }
        elsif ( ($line[1] eq "PTKVZ") || ($line[1] eq "PTKZU") ) {
        $state .= "-PTK";
        $verb = $state;
        }
        else {$verb = ();}
    }

    else {
        if ( ($line[1] eq "ADV") && (!defined $group) ) {
            $verb = "OPT";
        }
        elsif ( ($line[1] eq "PDS") || ($line[1] eq "PIS") ) {
            unless (defined $group) {
            $state = "GV0";
            $verb = $state;
            }
        }
        elsif ( ($line[1] eq "PPER") || ($line[1] eq "PRF") ) {
            unless (defined $group) {
            $state = "GV1";
            $verb = $state;
            }
        }
        elsif ( ($line[1] =~ m/V.FIN/) || ($line[1]=~ m/V.PP/) ) {
            $state = "GV2-ANF";
            $verb = $state;
        }
    elsif ( ($line[1] =~ m/KOU./) || ($line[1] eq "PTKZU") || ($line[1] eq "PRELS") || ($line[1] =~ m/PWAV/) || ($line[1]  eq "PAV") || ($line[1] eq "PWS") ) {
            $state = "GV0-END";
            $verb = $state;
        }
        else {$verb = ();}
    }


    if ( ($group =~ m/3/) && ($group !~ m/-P/) && ($group !~ m/-B/) && ($group !~ m/-KON/) ) {
        $valency++;
        $printv = $valency;
    }
    elsif ( ($line[1] eq "ADJD") && (!defined $group) ) {
            $valency++;
            $printv = $valency;
    }
    elsif ( ($line[1] eq "PIS") && (!defined $group) ) {
            $valency++;
            $printv = $valency;
    }
    elsif ( ($line[1] eq "PDS") || ($line[1] eq "PPER") || ($line[1] eq "PRELS") || ($line[1] eq "PRF") || ($line[1] =~ m/PW/)  || ($line[1] eq "PAV") ) {
        $valency++;
        $printv = $valency;
    }
    elsif ( ($line[1] eq "KON") || ($line[1] eq "\$,") || ($line[1] eq "\$(") ) {
        if ( $vpass == 1 ) {
            $valency = 0; $printv = (); $vpass = 0;
        }
        else {
            $printv = ();
        }
        @tempvpass = ();
    }
    elsif ($verb =~ m/[2-3]/) {
        $printv = 0;
        $vpass = 1;
    }
    else {$printv = ();}


    if ( $line[1] eq "\$," ) {
        if ( $state =~ m/[0-1]/ ) {
        $state .= "-W";
        }
        else {
        $state = ();
        }
    }

}

# output
print $line[0] . "\t" . $group . "\t" . $verb . "\t" . $printv . "\t" . $vpass . "\n";
