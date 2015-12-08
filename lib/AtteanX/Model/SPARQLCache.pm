package AtteanX::Model::SPARQLCache;


use v5.14;
use warnings;

use Moo;
use Types::Standard qw(InstanceOf ArrayRef ConsumerOf HashRef);
use Scalar::Util qw(reftype);
use namespace::clean;

extends 'AtteanX::Model::SPARQL';

has 'cache' => (
					 is => 'ro',
					 isa => InstanceOf['CHI::Driver'],
					 required => 1
					);

# Override the store's planner, to take back control
sub plans_for_algebra {
	return;
}

sub cost_for_plan { # TODO: Do this for real
	my $self	= shift;
	my $plan	= shift;
	if ($plan->isa('Attean::Plan::Quad')) {
		return 3;
	} elsif ($plan->isa('Attean::Plan::Table')) {
		return 2;
	} elsif ($plan->isa('AtteanX::Store::SPARQL::Plan::BGP')) {
		return 20;
	}
	return;
}

1;