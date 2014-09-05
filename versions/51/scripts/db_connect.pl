#!/usr/bin/env perl

=pod

 Copyright [1999-2014] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute

 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at

      http://www.apache.org/licenses/LICENSE-2.0

 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.


=cut


use strict;
use warnings;

# use Bio::EnsEMBL::Hive::Utils::Graph;
# use Bio::EnsEMBL::Hive::DBSQL::DBAdaptor;
# use Bio::EnsEMBL::Hive::DBSQL::SqlSchemaAdaptor;
use JSON;
use HTML::Template;

use lib ("./lib");
#use msg;

my $json_url = shift @ARGV || '{"version":["53"],"url":["mysql://ensro@127.0.0.1:2912/mp12_compara_nctrees_74clean2"]}';
my $hive_config_file = $ENV{GUIHIVE_BASEDIR} . "config/hive_config.json";

# Input data
my $url = decode_json($json_url)->{url}->[0];
my $version = decode_json($json_url)->{version}->[0];

# Set up @INC and paths for static content
my $project_dir = $ENV{GUIHIVE_BASEDIR} . "versions/$version/";
my $connection_template = "${project_dir}static/connection_details.html";

unshift @INC, $project_dir . "scripts/lib";
require msg;

unshift @INC, $project_dir . "ensembl-hive/modules";
require Bio::EnsEMBL::Hive::Utils::Graph;
require Bio::EnsEMBL::Hive::DBSQL::DBAdaptor;
require Bio::EnsEMBL::Hive::DBSQL::SqlSchemaAdaptor;

my $response = msg->new();

# Initialization
my $dbConn;
eval {
  $dbConn = Bio::EnsEMBL::Hive::DBSQL::DBAdaptor->new( -no_sql_schema_version_check => 1, -url => $url );
};
if ($@) {
  $response->err_msg($@);
  $response->status("FAILED");
}

if (defined $dbConn) {
    my ($graph, $status);
    eval {
	$graph = formAnalyses($dbConn);
	$status = formResponse($dbConn);
    };
    if ($@) {
	$response->err_msg("I have problems retrieving data from the database:$@");
	$response->status("FAILED");
    } else {
	$response->status($status);
	$response->out_msg($graph);
    }
} else {
    $response->err_msg("The provided URL seems to be invalid. Please check the URL and try again\n") unless($response->err_msg);
    $response->status("FAILED");
}

print $response->toJSON();

sub formResponse {
    my ($dbConn) = @_;
    my $info;

    $info->{db_name}   = $dbConn->dbc->dbname;
    $info->{host}      = $dbConn->dbc->host;
    $info->{port}      = $dbConn->dbc->port;
    $info->{driver}    = $dbConn->dbc->driver;
    $info->{username}  = $dbConn->dbc->username;
    $info->{hive_db_version} = get_hive_db_version();
    $info->{hive_code_version} = get_hive_code_version();
    # $info->{mysql_url} = "?username=" . $dbConn->dbc->username . "&host=" . $dbConn->dbc->host . "&dbname=" . $dbConn->dbc->dbname . "&port=" . $dbConn->dbc->port;

    my $template = HTML::Template->new(filename => $connection_template);
    $template->param(%$info);
    return $template->output();
}

sub formAnalyses {
    my ($dbConn) = @_;
    my $graph = Bio::EnsEMBL::Hive::Utils::Graph->new($dbConn, $hive_config_file);
    my $graphviz = $graph->build();

    return $graphviz->as_svg;
}


#######################
#  These two methods are also defined in scripts/db_fetch_patches.pl
#  It would be better to have them in a common base class or something?
sub get_hive_db_version {
  my $metaAdaptor      = $dbConn->get_MetaAdaptor;
  my $db_sql_schema_version   = eval { $metaAdaptor->fetch_value_by_key( 'hive_sql_schema_version' ); };
  return $db_sql_schema_version;
}

sub get_hive_code_version {
  # my $sqlSchemaAdaptor = $dbConn->get_SqlSchemaAdaptor;
  my $code_sql_schema_version =  Bio::EnsEMBL::Hive::DBSQL::SqlSchemaAdaptor->get_code_sql_schema_version();
  return $code_sql_schema_version;
}