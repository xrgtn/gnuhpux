#!/bin/sh

WHERE="."

find "$WHERE" -type f | \
while read F ; do
    case "z$F" in
        *.so);;
        *.so.*);;
        *) test -x "$F" || continue;;
    esac

    RUNPATHS0=`chrpath "$F" 2>/dev/null\
        | sed 's/^.*: RUNPATH=//'`
    [ "z$RUNPATHS0" = "z" ] && continue
    if ! [ -f ./chrpath.pl ] ; then
        cat > ./chrpath.pl <<'EOF'
#!/usr/bin/env perl

use strict;
use warnings;

sub acpath($) {
    my $x = $_[0];
    if ($x !~ /^\//) {
        (my $pwd = `pwd`) =~ s/[\r\n]*$//;
        $x = "$pwd/$x";
    };
    my $i = 100;
    $i-- while $x =~ s/\/\.($|\/)/$1/g and $i > 0;
    $i = 100;
    $i-- while $x =~ s/^\/\.\.($|\/)/\/$1/ and $i > 0;
    $i = 100;
    $i-- while $x =~ s/\/[^\/]+\/\.\.($|\/)/$1/g and $i > 0;
    return $x;
};

while (<STDIN>) {
    s/[\r\n]*$//;
    my @p = map {acpath($_)} split /:/;
    for (my $i = 0; $i <= $#p; $i++) {
        foreach my $re (@ARGV) {
            eval "\$p[\$i] =~ $re";
        };
    };
    my %k;
    my @up;
    foreach my $p (@p) {
        exists $k{$p} and next;
        "z$p" eq "z" and next;
        $k{$p} = 1;
        push(@up, $p);
    };
    print join(":", @up)."\n";
};
EOF
        chmod a+x ./chrpath.pl
    fi
    RUNPATHS1=`echo "$RUNPATHS0" | ./chrpath.pl "$@"`
    if [ "z$RUNPATHS1" != "z" ] && [ "z$RUNPATHS1" != "z$RUNPATHS0" ] ; then
        chrpath -r "$RUNPATHS1" "$F"
    fi
done

# vi:set sw=4 et:
