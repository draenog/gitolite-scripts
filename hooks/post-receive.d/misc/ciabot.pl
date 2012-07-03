#!/usr/bin/perl -w
#
# ciabot -- Mail a git log message to a given address, for the purposes of CIA
#
# Loosely based on cvslog by Russ Allbery <rra@stanford.edu>
# Copyright 1998  Board of Trustees, Leland Stanford Jr. University
#
# Copyright 2001, 2003, 2004, 2005  Petr Baudis <pasky@ucw.cz>
#
# This program is free software; you can redistribute it and/or modify it under
# the terms of the GNU General Public License version 2, as published by the
# Free Software Foundation.
#
# The master location of this file is in the Cogito repository
# (see http://www.kernel.org/git/).
#
# This program is designed to run as the .git/hooks/post-commit hook. It takes
# the commit information, massages it and mails it to the address given below.
#
# The calling convention of the post-commit hook is:
#
#	.git/hooks/post-commit $commit_sha1 $branch_name
#
# If it does not work, try to disable $xml_rpc in the configuration section
# below. Also, remember to make the hook file executable.
#
#
# Note that you can (and it might be actually more desirable) also use this
# script as the GIT update hook:
#
#	refname=${1#refs/heads/}
#	[ "$refname" = "master" ] && refname=
#	oldhead=$2
#	newhead=$3
#	for merged in $(git-rev-list $newhead ^$oldhead | tac); do
#		/path/to/ciabot.pl $merged $refname
#	done
#
# This is useful when you use a remote repository that you only push to. The
# update hook will be triggered each time you push into that repository, and
# the pushed commits will be reported through CIA.

use strict;
use vars qw ($project $noisy $rpc_uri
		$xml_rpc $ignore_regexp $alt_local_message_target);




### Configuration

# If using XML-RPC, connect to this URI.
$rpc_uri = 'http://cia.vc/RPC2';

# If set, the script will send CIA the full commit message. If unset, only the
# first line of the commit message will be sent.
$noisy = 0;

# This script can communicate with CIA either by mail or by an XML-RPC
# interface. The XML-RPC interface is faster and more efficient, however you
# need to have RPC::XML perl module installed, and some large CVS hosting sites
# (like Savannah or Sourceforge) might not allow outgoing HTTP connections
# while they allow outgoing mail. Also, this script will hang and eventually
# not deliver the event at all if CIA server happens to be down, which is
# unfortunately not an uncommon condition.
$xml_rpc = 1;

# This variable should contain a regexp, against which each file will be
# checked, and if the regexp is matched, the file is ignored. This can be
# useful if you do not want auto-updated files, such as e.g. ChangeLog, to
# appear via CIA.
#
# The following example will make the script ignore all changes in two specific
# files in two different modules, and everything concerning module 'admin':
#
# $ignore_regexp = "^(gentoo/Manifest|elinks/src/bfu/inphist.c|admin/)";
$ignore_regexp = "";

# It can be useful to also grab the generated XML message by some other
# programs and e.g. autogenerate some content based on it. Here you can specify
# a file to which it will be appended.
$alt_local_message_target = "";




### The code itself

use vars qw ($commit $tree @parent $author $committer);
use vars qw ($user $branch $rev @files $logmsg $message);
my $line;



### Input data loading


# The commit stuff
$commit = $ARGV[0];
$branch = $ARGV[1];
$project = $ARGV[2];

open COMMIT, "git cat-file commit $commit|" or die "git cat-file commit $commit: $!";
my $state = 0;
$logmsg = '';
while (defined ($line = <COMMIT>)) {
  if ($state == 1) {
    unless ($noisy or length($line)>1) {
      $state++;
      next;
    }
    $logmsg .= $line;
    next;
  } elsif ($state > 1) {
    next;
  }

  chomp $line;
  unless ($line) {
    $state = 1;
    next;
  }

  my ($key, $value) = split(/ /, $line, 2);
  if ($key eq 'tree') {
    $tree = $value;
  } elsif ($key eq 'parent') {
    push(@parent, $value);
  } elsif ($key eq 'author') {
    $author = $value;
  } elsif ($key eq 'committer') {
    $committer = $value;
  }
}
close COMMIT;
chomp $logmsg;


open DIFF, "git diff-tree -r $parent[0] $tree|" or die "git diff-tree $parent[0] $tree: $!";
while (defined ($line = <DIFF>)) {
  chomp $line;
  my @f;
  (undef, @f) = split(/\t/, $line, 2);
  push (@files, @f);
}
close DIFF;


# Figure out who is doing the update.
# XXX: Too trivial this way?
($user) = $author =~ /<(.*?)@/;


$rev = substr($commit, 0, 12);


# Module name
my $module = $ENV{GL_REPO};
$module =~ s/$ENV{GL_REPO_BASE_ABS}\/?(.*)\.git/$1/;


### Remove to-be-ignored files

@files = grep { $_ !~ m/$ignore_regexp/; } @files
  if ($ignore_regexp);
exit unless @files;



### Compose the mail message


my ($VERSION) = '1.0';
my $ts = time;

$message = <<EM
<message>
   <generator>
       <name>CIA Perl client for Git</name>
       <version>$VERSION</version>
   </generator>
   <source>
       <project>$project</project>
       <module>$module</module>
EM
;
$message .= "       <branch>$branch</branch>" if ($branch);
$message .= <<EM
   </source>
   <timestamp>
       $ts
   </timestamp>
   <body>
       <commit>
           <author>$user</author>
           <files>
EM
;

foreach (@files) {
  s/&/&amp;/g;
  s/</&lt;/g;
  s/>/&gt;/g;
  $message .= "  <file>$_</file>\n";
}

$logmsg =~ s/&/&amp;/g;
$logmsg =~ s/</&lt;/g;
$logmsg =~ s/>/&gt;/g;

$message .= <<EM
           </files>
           <log>
$logmsg
           </log>
       </commit>
   </body>
</message>
EM
;



### Write the message to an alt-target

if ($alt_local_message_target and open (ALT, ">>$alt_local_message_target")) {
  print ALT $message;
  close ALT;
}



### Send out the XML-RPC message


if ($xml_rpc) {
  # We gotta be careful from now on. We silence all the warnings because
  # RPC::XML code is crappy and works with undefs etc.
  $^W = 0;
  $RPC::XML::ERROR if (0); # silence perl's compile-time warning

  require RPC::XML;
  require RPC::XML::Client;

  my $rpc_client = new RPC::XML::Client $rpc_uri;
  my $rpc_request = RPC::XML::request->new('hub.deliver', $message);
  my $rpc_response = $rpc_client->send_request($rpc_request);

  unless (ref $rpc_response) {
    die "XML-RPC Error: $RPC::XML::ERROR\n";
  }
  exit;
}


# vi: set sw=2:
