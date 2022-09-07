package App::Schema::Data;

use strict;
use warnings;

use English;
use Error::Pure qw(err);
use Getopt::Std;

our $VERSION = 0.01;

# Constructor.
sub new {
	my ($class, @params) = @_;

	# Create object.
	my $self = bless {}, $class;

	# Object.
	return $self;
}

# Run.
sub run {
	my $self = shift;

	# Process arguments.
	$self->{'_opts'} = {
		'h' => 0,
		'p' => '',
		'u' => '',
		'v' => undef,
	};
	if (! getopts('hp:u:v:', $self->{'_opts'})
		|| $self->{'_opts'}->{'h'}
		|| @ARGV < 2) {

		print STDERR "Usage: $0 [-h] [-p password] [-u user] [-v schema_version] [--version] dsn schema_data_module\n";
		print STDERR "\t-h\t\t\tPrint help.\n";
		print STDERR "\t-p password\t\tDatabase password.\n";
		print STDERR "\t-u user\t\t\tDatabase user.\n";
		print STDERR "\t-v schema_version\tSchema version (default is ".
			"latest version).\n";
		print STDERR "\t--version\t\tPrint version.\n";
		print STDERR "\tdsn\t\t\tDatabase DSN. e.g. dbi:SQLite:dbname=ex1.db\n";
		print STDERR "\tschema_data_module\tName of Schema data module.\n";
		return 1;
	}
	$self->{'_dsn'} = shift @ARGV;
	$self->{'_schema_data_module'} = shift @ARGV;

	eval "require $self->{'_schema_data_module'}";
	if ($EVAL_ERROR) {
		err 'Cannot load Schema data module.',
			'Module name', $self->{'_schema_data_module'},
			'Error', $EVAL_ERROR,
		;
	}

	my $data_module;
	my $data_version;
	if ($self->{'_schema_data_module'}->can('new')) {
		my $versioned_data = $self->{'_schema_data_module'}->new(
			$self->{'_opts'}->{'v'} ? (
				'version' => $self->{'_opts'}->{'v'},
			) : (),
		);
		$data_module = $versioned_data->schema_data;
		$data_version = $versioned_data->version;
	} else {
		$data_module = $self->{'_schema_data_module'};
	}
	my $data = eval {
		$data_module->new(
			'db_options' => {},
			'db_password' => $self->{'_opts'}->{'p'}, 
			'db_user' => $self->{'_opts'}->{'u'},
			'dsn' => $self->{'_dsn'},
		);
	};
	if ($EVAL_ERROR) {
		err 'Cannot connect to Schema database.',
			'Error', $EVAL_ERROR,
		;
	}

	# Check Schema::Data::Data instance.
	if (! $data->isa('Schema::Data::Data')) {
		err "Schema data module must be a 'Schema::Data::Data' instance.";
	}

	$data->insert;

	my $print_version = '';
	if (defined $data_version) {
		$print_version = '(v'.$data_version.') ';
	}
	print "Schema data ${print_version}from '$self->{'_schema_data_module'}' was ".
		"inserted to '$self->{'_dsn'}'.\n";

	return 0;
}

1;


__END__

=pod

=encoding utf8

=head1 NAME

App::Schema::Data - Base class for schema-data script.

=head1 SYNOPSIS

 use App::Schema::Data;

 my $app = App::Schema::Data->new;
 my $exit_code = $app->run;

=head1 METHODS

=head2 C<new>

 my $app = App::Schema::Data->new;

Constructor.

Returns instance of object.

=head2 C<run>

 my $exit_code = $app->run;

Run.

Returns 1 for error, 0 for success.

=head1 ERRORS

 run():
         Cannot connect to Schema database.
                 Error: %s
         Cannot load Schema data module.
                 Module name: %s
                 Error: %s
         Schema data module must be a 'Schema::Data::Data' instance.

=head1 EXAMPLE

=for comment filename=insert_commons_vote_data.pl

 # Need to deploy sqlite.db via schema-deploy dbi:SQLite:dbname=sqlite.db Schema::Commons::Vote

 use strict;
 use warnings;

 use App::Schema::Data;

 # Arguments.
 @ARGV = (
         'dbi:SQLite:dbname=sqlite.db',
         'Schema::Data::Commons::Vote',
 );

 # Run.
 exit App::Schema::Data->new->run;

 # Output like:
 # Schema data from 'Schema::Data::Commons::Vote' was inserted to 'dbi:SQLite:dbname=sqlite.db'.

=head1 DEPENDENCIES

L<English>,
L<Error::Pure>,
L<Getopt::Std>.

=head1 REPOSITORY

L<https://github.com/michal-josef-spacek/App-Schema-Data>

=head1 AUTHOR

Michal Josef Špaček L<mailto:skim@cpan.org>

L<http://skim.cz>

=head1 LICENSE AND COPYRIGHT

© 2022 Michal Josef Špaček

BSD 2-Clause License

=head1 VERSION

0.01

=cut
