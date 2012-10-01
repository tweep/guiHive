#!/usr/bin/env perl

use strict;
use warnings;

use Bio::EnsEMBL::Hive::URLFactory;
use JSON::XS;
use HTML::Template;
use Data::Dumper;

use msg;

my $json_url = shift @ARGV || '{"url":["mysql://ensro@127.0.0.1:2912/mp12_compara_nctrees_69b"]}';
my $analyses_template = $ENV{GUIHIVE_BASEDIR} . 'static/pipeline_diagram.html';

my $url = decode_json($json_url)->{url}->[0];

my $dbConn = Bio::EnsEMBL::Hive::URLFactory->fetch($url);
my $response = msg->new();

if (defined $dbConn) {
  my $all_analyses;
  eval {
    $all_analyses = $dbConn->get_AnalysisAdaptor()->fetch_all();
  };
  if ($@) {
      $response->status("I can't get all the analysis from the database: $@");
  } else {
      $response->status(formResponse($dbConn));
      $response->out_msg(formAnalyses($all_analyses));
  }
} else {
    $response->status("I can't connect to the database. Please, check the URL and try again");
}

print $response->toJSON();

sub formResponse {
  my ($dbConn) = @_;
  my $resp;
  $resp .= "<p>";
  $resp .= "DB name: ". $dbConn->dbc->dbname. "<br />";
  $resp .= "Host: ". $dbConn->dbc->host. "<br />";
  $resp .= "Port: ". $dbConn->dbc->port. "<br />";
  $resp .= "Driver: ". $dbConn->dbc->driver. "<br />";
  $resp .= "Username: ". $dbConn->dbc->username. "<br />";
  $resp .= "</p>";
  return $resp;
}

sub formError {
  return "I can't connect to the database: Please check the URL and try again";
}

sub formAnalyses {
    my ($all_analyses) = @_;
    my $template = HTML::Template->new(filename => $analyses_template);
    $template->param(analyses => [ map{ {logic_name_id => $_->logic_name, logic_name => $_->logic_name} } @$all_analyses] );
    return $template->output();
}
