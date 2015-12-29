package AtteanX::Query::Cache::Analyzer;

use 5.010001;
use strict;
use warnings;

our $AUTHORITY = 'cpan:KJETILK';
our $VERSION   = '0.001';

use Moo;
use Attean::RDF qw(triplepattern variable iri);
use Types::Standard qw(Str Int InstanceOf);
use Types::URI -all;
use AtteanX::Parser::SPARQL;
use AtteanX::Query::Cache::Analyzer::Model;
use AtteanX::QueryPlanner::Cache;
use AtteanX::Query::Cache::Analyzer::QueryPlanner;

use Carp;

has 'query' => (is => 'ro', required => 1, isa => Str);
has 'base_uri' => (is => 'ro', default => 'http://default.invalid/');

has 'model' => (is => 'ro', isa => InstanceOf['AtteanX::Query::Cache::Analyzer::Model'], required => 1);

has 'graph' => (is => 'ro', isa => InstanceOf['Attean::IRI'], default => sub { return iri('http://example.invalid')});

has 'threshold' => (is => 'ro', isa => Int, default => '10');

sub analyze {
	my $self = shift;
	my $parser = AtteanX::Parser::SPARQL->new();
	my ($algebra) = $parser->parse_list_from_bytes($self->query, $self->base_uri); # TODO: this is a bit of cargocult
	# First, we find the cost of the plan with the current cache:
	my $curplanner = AtteanX::QueryPlanner::Cache->new;
	my $curplan = $curplanner->plan_for_algebra($algebra, $self->model, [$self->graph]);
	my $curcost = $curplanner->cost_for_plan($curplan, $self->model);
	warn $curcost;
	my %costs;
	my $planner = $curplanner; #AtteanX::Query::Cache::Analyzer::QueryPlanner->new;
	foreach my $bgp ($algebra->subpatterns_of_type('Attean::Algebra::BGP')) {
		foreach my $triple (@{ $bgp->triples }) { # TODO: May need quads
			next if ($self->model->is_cached($triple));
			my $key = $triple->canonicalize->as_string;
			$self->model->try($key);
			my $plan = $planner->plan_for_algebra($algebra, $self->model, [$self->graph]);
			$costs{$key} = $planner->cost_for_plan($plan, $self->model);
		}
	}
	warn Data::Dumper::Dumper(\%costs);
}

1;
