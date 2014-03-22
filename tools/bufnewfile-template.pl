#!/usr/bin/env perl
use strict;
use warnings;
use utf8;
binmode STDOUT, ":utf8";

my %lookup = (
    pm  => \&pm,
    h   => \&hpp,
    hpp => \&hpp,
);

main(@ARGV); exit;

sub main {
    ( my $file = shift ) =~ /\.([^.]+)$/;
    my $suffix = $1 || "";

    if (my $code = $lookup{$suffix}) {
        print $code->($file, $suffix);
    } elsif (my $data = get_data_section($suffix)) {
        print $data;
    } else {
        print "";
    }
}

sub get_data_section {
    my $suffix = shift;
    # taken from Data::Section::Simple
    my $data = do { local $/; <DATA> };
    close DATA;
    my @data = split /^@@\s+(.+?)\s*\n/m, $data;
    shift @data;
    while (@data) {
        my ($name, $content) = splice @data, 0, 2;
        next if $name ne $suffix;
        $content =~ s/(\n{2})\z/\n/xsm;
        return $content;
    }
    return "";
}

sub heredoc {
    my $string = shift;
    $string =~ s/\A\n//xsm;
    $string =~ s/[ \t]*\z//xsm;
    if ($string =~ m/\A ([ \t]+) /xsm) {
        my $padding = length $1;
        $string =~ s/^ ([^\n]{$padding}) //gxsm;
    }
    return $string;
}

sub pm {
    my $file = shift;
    require Cwd;
    require File::Spec;
    $file = glob $file; # resolve ~
    if (!File::Spec->file_name_is_absolute($file)) {
        $file = File::Spec->catfile(Cwd::getcwd(), $file);
    }
    $file =~ s{.*/lib/}{} or $file =~ s{.*/([^/]+)}{$1};
    $file =~ s{/}{::}g; $file =~ s{\.pm$}{};
    return heredoc qq{
        package $file;
        use strict;
        use warnings;
        our \$VERSION = "0.001";


        1;
    };
}

sub hpp {
    my $file = shift;
    require File::Basename;
    my $basename = File::Basename::basename($file);
    $basename =~ s/\.[^.]+$//;
    $basename = uc $basename;
    return heredoc qq{
        #ifndef ${basename}_H_
        #define ${basename}_H_


        #endif
    };
}

__DATA__

@@ java
//import java.util.*;

public class Main {
    public static void main(String[] args) {

    }
}

@@ pl
#!/usr/bin/env perl
use strict;
use warnings;
use utf8;


@@ c
#include <stdio.h>

/* int main(int argc, char* argv[]) { */
int main(void) {

  return 0;
}

@@ cpp
#include <string>
#include <iostream>
using namespace std;

/* int main(int argc, char *argv[]) { */
int main(void) {


  return 0;
}

@@ html
<!DOCTYPE html>
<html lang="ja">
<head>
    <meta charset="utf-8">
    <title>hoge</title>
    <!--
        <script src="/script.js"></script>
        <link rel="stylesheet" href="/css.css">
    -->
</head>
<body>

</body>
</html>

@@ t
use strict;
use warnings;
use utf8;
use Test::More;


done_testing;

@@ rb
#!/usr/bin/env ruby
# coding: utf-8

@@ py
#!/usr/bin/env python

