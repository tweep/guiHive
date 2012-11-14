#!/usr/bin/env perl

use strict;
use warnings;
use JSON::PP;
use Data::Dumper;
use Bio::EnsEMBL::Hive::URLFactory;

my $json_data = shift @ARGV || '{"url":["mysql://ensadmin:ensembl@127.0.0.1:2912/mp12_compara_nctrees_69d"], "job_id":["5"]}';

my $var = decode_json($json_data);
print STDERR Dumper $var;
my $url = $var->{url}->[0];
my $job_id = $var->{job_id}->[0];
$job_id =~ s/job_//;

my $dbConn = Bio::EnsEMBL::Hive::URLFactory->fetch($url);

my $resp;
if (defined $dbConn) {
  my $job;
  eval {
    $job = $dbConn->get_AnalysisJobAdaptor()->fetch_by_dbID($job_id);
  };
  if ($@) {
    $resp = "[ERROR]";
  }
  if (!defined $job) {
    $resp = "[ERROR]";
  } else {
    my $analysis_id = $job->analysis_id();
    my $analysis = $dbConn->get_AnalysisAdaptor()->fetch_by_analysis_id($analysis_id);
    my $max_retry_count = $analysis->max_retry_count();
    for my $i (0..$max_retry_count) {
      $resp->{$i} = $i;
    }
  }
}

## keys are sorted in numerical order
my $js = JSON::PP->new->allow_nonref->sort_by(sub {$JSON::PP::a <=> $JSON::PP::b});
print $js->encode($resp);

