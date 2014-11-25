#=#=#=# cliPSafe #=#=#=#
use DateTime;

sub getcmd {
    my $prompt = shift;

    print "$prompt";
    my $cmd = <STDIN>;
    chomp($cmd);

    return $cmd;
}

sub ls {
    my ($pwsafe, $pwd) = @_;

    if ($pwd eq "") {
        #if($#pwsafe > 0 || $pwsafe->){}
        print "${under}Groups:$norm\n";
        foreach my $x (sort keys %$pwsafe) {
            print "  $x\n" if $x ne "";
        }
    }

    my $h = $pwsafe->{$pwd};
    if (keys %$h) {
        print "${under}Entries:$norm\n";
        foreach my $x (sort keys %$h) {
            print "  $x\n";
        }
    }

    print "\n";
}

sub printfield {
    my ($e, $f, $ftxt) = @_;

    if (exists $e->{$f}) {
        my $txt = "$e->{$f}";

        $txt = DateTime->from_epoch(epoch => $txt) if $f =~ m/Time$/;

        print "$bold$ftxt$norm$txt\n" if $txt =~ m/./;
    }
}

sub printentry {
    my ($pwsafe, $pwd, $entry) = @_;

    print "$bold$under$pwd/$entry$norm\n";
    my $eh = $pwsafe->{$pwd}->{$entry};
    printfield ($eh, "User",        "User:      ");
    printfield ($eh, "Password",    "Password:  ");
    printfield ($eh, "AutoType",    "AutoType:  ");
    printfield ($eh, "URL",         "URL:       ");
    printfield ($eh, "LifeTime",    "LifeTime:  ");
    printfield ($eh, "Policy",      "Policy:    ");
    printfield ($eh, "PWHistory",   "PWHistory: ");
    printfield ($eh, "CTime",       "Created on:                ");
    printfield ($eh, "PWMTime",     "Password last changed on:  ");
    printfield ($eh, "ATime" ,      "Last accessed on:          ");
    printfield ($eh, "RecordMTime", "Any field last changed on: ");
    printfield ($eh, "Notes",       "Notes:\n");
    print "\n";
}

sub cat {
    my ($pwsafe, $pwd, $entry, $flatlist) = @_;
    my ($g_matches, $e_matches);
    my $count = 0;

    if ($flatlist) {
        foreach my $group (sort keys %$pwsafe) {
            my $gh = $pwsafe->{$group};
            foreach my $e (sort keys %$gh) {
                if ($e =~ m/$entry/i) {
                    $count++;
                    $g_matches->{$count} = $group;
                    $e_matches->{$count} = $e;
                }
            }
        }
    } else {
        my $gh = $pwsafe->{$pwd};
        foreach my $e (sort keys %$gh) {
            if ($e =~ m/$entry/i) {
                $count++;
                $g_matches->{$count} = $pwd;
                $e_matches->{$count} = $e;
            }
        }
    }

    if ($count == 0) {
        print "No match for $entry\n\n";
        return;
    }

    my $num = 1;
    if ($count > 1) {
        foreach my $n (sort {$a <=> $b} keys %$g_matches) {
            print "$n - $g_matches->{$n}/$e_matches->{$n}\n";
        }
        $num = getcmd ("Choose (0 to cancel): ");
    }

    if ($num =~ m/^\s*\d+\s*$/ && $num <= $count && $num > 0) {
        printentry ($pwsafe, $g_matches->{$num}, $e_matches->{$num});
    }
}

sub cd {
    my ($pwsafe, $pwd, $entry) = @_;

    if ($entry =~ m/\/|\\/) {
        print "\n";
        return "";

    } elsif (exists $pwsafe->{$entry}) {
        print "\n";
        return $entry;

    } else {
        print "Group not found: $entry\n\n";
    }

    return $pwd;
}

sub printhelp {
    print "Valid commands are:\n";
    print "    ls [group]      - list groups & entries\n";
    print "    cd [group]      - change directory; 'cd /' or 'cd' alone takes you back to the root\n";
    print "    cat [-i] <rxp>  - display an entry; use -i to ignore groups and search entire db\n";
    print "    help|?          - display this help message\n";
    print "    exit|quit       - exit clipsafe\n\n";
    print "Commands ls and cd support tab completion on group names\n\n";
}

sub usage {
    print "cliPSafe version 1.2, Copyright (C) 2008-2014 Ross Palmer Mohn\n";
    print "cliPSafe comes with ABSOLUTELY NO WARRANTY. This is free software,\n";
    print "and you are welcome to redistribute it under certain conditions.\n\n";

    print "Usage:\n";
    print "    clipsafe [-h] [-f dbfname] [rxp]\n\n";
}

sub getfname {
    my $fname = shift;
    my $pname = "$ENV{HOME}/.passwordsafe/preferences.properties";
    my %prefs;

    if ($fname eq "" && -f $pname) {
        open FILE, $pname;
        while (<FILE>) {
            my ($k, $v) = split (/=/);
            if (defined $v) {
                chomp ($v);
                $prefs{$k} = $v;
            }
        }
        close FILE;
        $fname = $prefs{"mru.1"} if exists $prefs{"mru.1"};
    }

    if ($fname eq "") {
        $fname = getcmd("Enter database file name: ");
    }

    die "File not found: $fname\n" unless $fname && -f $fname;

    print "${bold}File: $norm$fname\n";

    return $fname;
}

#-- main --#

my $rxp = "";
my $fname = "";

if ($#ARGV >= 0 && $ARGV[0] =~ m/-h/i) {
    usage();
    exit;
} elsif ($#ARGV == 0 && $ARGV[0] =~ m/-f/i) {
    print "Bad command line.\n";
    usage();
    exit;
} elsif ($#ARGV == 0) {
    $rxp = "$ARGV[0]";
} elsif ($#ARGV > 0 && $ARGV[0] =~ m/-f/i) {
    shift(@ARGV);
    $fname = shift(@ARGV);
    $rxp = join (" ", @ARGV);
} else {
    $rxp = join (" ", @ARGV);
}

my $file = getfname($fname);
my $comb = enter_combination();
my $pwsafe = open_safe($file, $comb);
my $pwd = "";
print "\n";

if ($rxp ne "") {
    cat ($pwsafe, "", "$rxp", 1);
    exit;
}

while(1) {
    my @groups;
    foreach my $grp (sort keys %$pwsafe) {
        push (@groups, "$grp");
    }
    my $cmd = Complete ("${bold}cliPSafe:$pwd> $norm", @groups);

    if ($cmd =~ m/^\s*(exit|quit)\s*$/i) {
        exit;
    } elsif ($cmd =~ m/^\s*ls\s+(.+)\s*$/i) {
        ls ($pwsafe, $1);
    } elsif ($cmd =~ m/^\s*ls\s*$/i) {
        ls ($pwsafe, $pwd);
    } elsif ($cmd =~ m/^\s*c(d|g)\s+(.+)\s*$/i) {
        $pwd = cd ($pwsafe, $pwd, "$2");
    } elsif ($cmd =~ m/^\s*c(d|g)\s*$/i) {
        $pwd = cd ($pwsafe, "$pwd", "/");
    } elsif ($cmd =~ m/^\s*(cat|show)\s+-(i|l)\s+(.+)\s*$/i) {
        cat ($pwsafe, $pwd, "$3", 1);
    } elsif ($cmd =~ m/^\s*(cat|show)\s+(.+)\s*$/i) {
        cat ($pwsafe, $pwd, "$2", 0);
    } elsif ($cmd =~ m/^\s*(help|\?)\s*$/i) {
        printhelp;
    } else {
        print "Bad command: $cmd\n\n";
        printhelp;
    }
}
#=#=#=# cliPSafe #=#=#=#
