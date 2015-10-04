#!/usr/bin/env perl
use strict;
use warnings;
use utf8;
binmode STDOUT, ":utf8";

my %lookup = (
    pm  => \&pm,
    pm6 => \&pm,
    h   => \&hpp,
    hpp => \&hpp,
);

main(@ARGV); exit;

sub main {
    ( my $file = shift ) =~ /\.([^.]+)$/;
    my $suffix = $1 || "";

    my $data;
    if (my $code = $lookup{$suffix}) {
        print $code->($file, $suffix);
    } elsif ($data = get_data_section($file)) {
        print $data;
    } elsif ($data = get_data_section($suffix)) {
        print $data;
    } else {
        print "";
    }
}

my %data;
sub get_data_section {
    my $want = shift;
    # taken from Data::Section::Simple
    unless (%data) {
        my $data = do { local $/; <DATA> };
        close DATA;
        my @data = split /^@@\s+(.+?)\s*\n/m, $data;
        shift @data;
        while (@data) {
            my ($name, $content) = splice @data, 0, 2;
            $content =~ s/\n{2}\z/\n/xsm;
            $data{$name} = $content;
        }
    }
    return $data{$want} || "";
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
    $file =~ s{/}{::}g;
    my $is_pm6 = $file =~ /pm6$/;
    $file =~ s{\.pm6?$}{};
    my $pm = heredoc qq{
        package $file;
        use strict;
        use warnings;
        use utf8;


        1;
    };
    my $pm6 = heredoc qq{
        use v6;
        unit class $file;

    };
    $is_pm6 ? $pm6 : $pm;
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
import java.util.*;

public class Main {
  public static void main(String[] args) {

  }
}

@@ pl
#!/usr/bin/env perl
use 5.14.0;
use warnings;
use utf8;


@@ p6
#!/usr/bin/env perl6
use v6;


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
  <script src="script.js"></script>
  <link href="css.css" rel="stylesheet" />
  -->
</head>
<body>
  <!--
  <ul>
    <li></li>
  </ul>
  -->

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
# coding: utf-8

@@ fabfile.py
# coding: utf-8
from fabric.api import *

@task
def hello():
    run("echo %s" % "hello")

@@ Dockerfile
FROM ubuntu:14.04
MAINTAINER Shoichi Kaji <skaji@cpan.org>

RUN locale-gen en_US en_US.UTF-8
RUN ln -sf /usr/share/zoneinfo/Japan /etc/localtime
RUN dpkg-reconfigure locales

RUN apt-get update -y
RUN env DEBIAN_FRONTEND=noninteractive \
    apt-get upgrade -y
RUN env DEBIAN_FRONTEND=noninteractive \
    apt-get install -y build-essential wget tar git bzip2 curl libssl-dev
RUN apt-get clean -y
