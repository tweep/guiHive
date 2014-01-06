=pod

=head1 NAME

    Bio::EnsEMBL::Hive::DBSQL::SqlSchemaAdaptor

=head1 SYNOPSIS

    Bio::EnsEMBL::Hive::DBSQL::SqlSchemaAdaptor->get_code_sql_schema_version();

=head1 DESCRIPTION

    This is currently an "objectless" adaptor for finding out the apparent code's SQL schema version

=head1 CONTACT

    Please contact ehive-users@ebi.ac.uk mailing list with questions/suggestions.

=cut


package Bio::EnsEMBL::Hive::DBSQL::SqlSchemaAdaptor;

use strict;

sub find_all_sql_schema_patches {

    my %all_patches = ();

    if(my $hive_root_dir = $ENV{'EHIVE_ROOT_DIR'} ) {
        foreach my $patch_path ( split(/\n/, `ls -1 $hive_root_dir/sql/patch_20*.*sql*`) ) {
            my ($patch_name, $driver) = split(/\./, $patch_path);

            $driver = 'mysql' if ($driver eq 'sql');    # for backwards compatibility

            $all_patches{$patch_name}{$driver} = $patch_path;
        }
    } # otherwise will sliently return an empty hash

    return \%all_patches;
}


sub get_sql_schema_patches {
    my ($self, $after_version, $driver) = @_;

    my $all_patches         = $self->find_all_sql_schema_patches();
    my $code_schema_version = $self->get_code_sql_schema_version();

    my @ordered_patches = ();
    foreach my $patch_key ( (sort keys %$all_patches)[$after_version..$code_schema_version-1] ) {
        if(my $patch_path = $all_patches->{$patch_key}{$driver}) {
            push @ordered_patches, $patch_path;
        } else {
            return;
        }
    }

    return \@ordered_patches;
}


sub get_code_sql_schema_version {
    my ($self) = @_;

    return scalar( keys %{ $self->find_all_sql_schema_patches() } );   # 0 probably means $ENV{'EHIVE_ROOT_DIR'} not set correctly
}

1;

