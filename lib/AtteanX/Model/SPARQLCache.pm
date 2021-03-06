package AtteanX::Model::SPARQLCache;


use v5.14;
use warnings;

use Moo;
use Types::Standard qw(InstanceOf);
use namespace::clean;

extends 'AtteanX::Model::SPARQL';
with 'MooX::Log::Any';

has 'cache' => (
					 is => 'ro',
					 isa => InstanceOf['CHI::Driver'],
					 required => 1
					);

# Override the store's planner, to take back control
sub plans_for_algebra {
	return;
}

sub cost_for_plan {
 	my $self	= shift;
 	my $plan	= shift;
 	my $planner	= shift;
#	warn $plan->as_string;
	if ($plan->isa('Attean::Plan::Table')) {
 		return 2;
	} elsif ($plan->isa('Attean::Plan::Quad')) {
 		return 100000;
	} elsif ($plan->isa('AtteanX::Store::SPARQL::Plan::BGP')) {
		# BGPs should have a cost proportional to the number of triple patterns,
		# but be much more costly if they contain a cartesian product.
		$self->log->trace('Estimating cost for single BGP');
		if ($plan->children_are_variable_connected) {
			return 20 * scalar(@{ $plan->children });
		} else {
			return 200 * scalar(@{ $plan->children });
		}
 	} else {
		my @bgps = $plan->subpatterns_of_type('AtteanX::Store::SPARQL::Plan::BGP');
		my $cost;
		foreach my $bgp (@bgps) {
			if ($bgp->children_are_variable_connected) {
				$cost += 10 * scalar(@{ $bgp->children }) + 26;
			} else {
				$cost += 100 * scalar(@{ $bgp->children }) + 35;
			}
		}
		if (defined($cost) && $self->log->is_trace) {
			$self->log->trace('Total cost for all BGPs is ' . $cost);
		}
		return $cost;
	}
 	return;
};

sub is_cached {
	my $self = shift;
	my $keypattern = shift;
	return $self->cache->is_valid($keypattern);
}


1;
