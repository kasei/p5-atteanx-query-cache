=pod

=encoding utf-8

=head1 PURPOSE

Test around the post-execution analysis.

=head1 SYNOPSIS

It may come in handy to enable logging for debugging purposes, e.g.:

  LOG_ADAPTER=Screen DEBUG=1 prove -lv t/analysis.t

This requires that L<Log::Any::Adapter::Screen> is installed.

=head1 AUTHOR

Kjetil Kjernsmo E<lt>kjetilk@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2015 by Kjetil Kjernsmo.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.


=cut

use v5.14;
use autodie;
use utf8;
use Test::Modern;
use Digest::SHA qw(sha1_hex);
use CHI;
#use Carp::Always;

use Attean;
use Attean::RDF;
use AtteanX::Query::Cache::Analyzer;
use Data::Dumper;
use AtteanX::Model::SPARQLCache;
use Log::Any::Adapter;
Log::Any::Adapter->set($ENV{LOG_ADAPTER} || 'Stderr') if ($ENV{TEST_VERBOSE});

my $cache = CHI->new( driver => 'Memory', global => 1 );

# my $p	= AtteanX::QueryPlanner::Cache->new;
# isa_ok($p, 'Attean::QueryPlanner');
# isa_ok($p, 'AtteanX::QueryPlanner::Cache');
# does_ok($p, 'Attean::API::CostPlanner');

my $query = <<'END';
SELECT * WHERE {
	?s <p> "1" .
   ?s <p> ?o .
	?s <q> "xyz" . 
	?a <b> <c> . 
	?s <q> <a> .
}
END

$query = <<'END';
SELECT * WHERE {
  ?a <c> ?s . 
  ?s <p> ?o . 
  ?o <b> "2" .
}
END


my $store = Attean->get_store('SPARQL')->new('endpoint_url' => iri('http://test.invalid/'));
my $model = AtteanX::Query::Cache::Analyzer::Model->new(store => $store, cache => $cache);

{
	$model->cache->set('?v002 <p> ?v001 .', {'<http://example.org/foo>' => ['<http://example.org/bar>'],
														  '<http://example.com/foo>' => ['<http://example.org/baz>', '<http://example.org/foobar>']});
	my $analyzer = AtteanX::Query::Cache::Analyzer->new(model => $model, query => $query);
	my @patterns = $analyzer->best_cost_improvement;
#	warn Data::Dumper::Dumper(\@patterns);
	is(scalar @patterns, 2, '2 patterns to submit');
	foreach my $pattern (@patterns) {
#		warn $pattern->as_string;
		isa_ok($pattern, 'Attean::TriplePattern');
	}
}
