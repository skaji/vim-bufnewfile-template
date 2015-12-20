#!/usr/bin/env perl
use strict;
use warnings;
use utf8;
use File::Basename qw(basename dirname);
use Cwd 'abs_path';
binmode STDOUT, ":utf8";

my %lookup = (
    pm  => \&pm,
    pm6 => \&pm,
    h   => \&h,
    hpp => \&h,
    t   => \&t,
    "CMakeLists.txt" => \&cmake,
);

main(@ARGV); exit;

sub main {
    ( my $file = shift ) =~ /\.([^.]+)$/;
    my $suffix = $1 || "";
    my $basename = basename $file;

    my $data;
    if (my $code = $lookup{$suffix} || $lookup{$basename}) {
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

sub template {
    my ($name, $arg) = @_;
    my $data = get_data_section($name);
    $data =~ s/
        \{\{
            \s* ([^\s\}]+) \s*
        \}\}
    /$arg->{$1} || die "Missing '$1' param in '$name' template" /exg;
    $data;
}

sub pm {
    my $file = shift;
    $file = glob $file; # resolve ~
    $file = abs_path($file);
    $file =~ s{.*/lib/}{} or $file =~ s{.*/([^/]+)}{$1};
    $file =~ s{/}{::}g;
    my $type = $file =~ /pm6$/ ? "pm6" : "pm";
    $file =~ s{\.pm6?$}{};
    template($type => { name => $file });
}
sub t {
    my $file = shift;
    $file = glob $file; # resolve ~
    $file = abs_path($file);
    my $is_perl6;
    my $pwd = dirname($file);
    while ($pwd ne "/") {
        if (grep { -f "$pwd/$_" } "META6.json", "META.info") {
            $is_perl6 = 1;
            last;
        } else {
            $pwd = abs_path("$pwd/..");
        }
    }
    get_data_section( $is_perl6 ? "t6" : "t" );
}

sub h {
    my $file = shift;
    my $basename = basename($file);
    $basename =~ s/\.([^.]+)$//;
    my $suffix = ($1 || "") eq "h" ? "H" : "HPP";
    $basename = uc $basename;
    template("h" => { name => "${basename}_${suffix}_"});
}

sub cmake {
    my $file = shift;
    my $dir = basename( dirname( abs_path($file) ) );
    template( "CMakeLists.txt" => { name => $dir } );
}

__DATA__

@@ h
#ifndef {{ name }}
#define {{ name }}


#endif

@@ pm
package {{ name }};
use strict;
use warnings;


1;

@@ pm6
use v6;
unit class {{ name }};


@@ t
use strict;
use warnings;
use Test::More;


done_testing;

@@ t6
use v6;
use Test;


done-testing;

@@ java
import java.util.*;

public class Main {
  public static void main(String[] args) {

  }
}

@@ pl
#!/usr/bin/env perl
use 5.22.1;
use warnings;
use experimental qw/ postderef signatures /;


@@ p6
#!/usr/bin/env perl6
use v6;


@@ c
#include <stdio.h>

/* int main(int argc, char *argv[]) { */
int main(void) {

  return 0;
}

@@ cpp
#include <string>
#include <iostream>
using namespace std;

int main(int /*argc*/, char * /*argv*/ []) {

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

@@ rb
#!/usr/bin/env ruby
# coding: utf-8

@@ py
#!/usr/bin/env python
# coding: utf-8

@@ fabfile.py
# coding: utf-8
from fabric.api import *
import os

if os.path.isfile(os.path.expanduser(env.ssh_config_path)):
    env.use_ssh_config = True

# fab -H localhost hello:msg="another msg"
@task
def hello(msg='test'):
    run("echo {msg}".format(msg=msg))

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

@@ CMakeLists.txt
CMAKE_MINIMUM_REQUIRED (VERSION 2.6)
PROJECT ({{ name }})

SET (VERSION_MAJOR 1)
SET (VERSION_MINOR 0)

CONFIGURE_FILE ("${PROJECT_SOURCE_DIR}/config.hpp.in" "${PROJECT_BINARY_DIR}/config.hpp")

# overwrite MY_PREFIX by `cmake -DMY_PREFIX=foo .`
if (NOT DEFINED MY_PREFIX)
  SET (MY_PREFIX "$ENV{HOME}/local")
endif ()
INCLUDE_DIRECTORIES ("${MY_PREFIX}/include")
SET (CMAKE_LIBRARY_PATH "${MY_PREFIX}/lib")

FILE (GLOB SOURCE_FILES src/*.cpp src/*.c)

SET (WARNING_FLAGS "-Wall -Wextra -Werror")
SET (CMAKE_C_FLAGS   "-O2 -g ${WARNING_FLAGS} ${CMAKE_C_FLAGS}")
SET (CMAKE_CXX_FLAGS "-O2 -g ${WARNING_FLAGS} ${CMAKE_CXX_FLAGS}")

ADD_EXECUTABLE ({{ name }} ${SOURCE_FILES})
# or
# ADD_LIBRARY ({{ name }} ${SOURCE_FILES})

# example of linking library
# FIND_LIBRARY (ATS_LIBRARY atscppapi REQUIRED)
# TARGET_LINK_LIBRARIES (main ${ATS_LIBRARY})
