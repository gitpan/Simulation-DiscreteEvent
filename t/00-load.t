#!perl -T

use Test::More 0.63;

BEGIN {
    plan tests => 5;
    for ( '', qw(::Server ::Event ::NumericState ::Recorder) ) {
        my $module = "Simulation::DiscreteEvent$_";
        use_ok( $module, 0.05 ) || BAIL_OUT("Failed to load $module");
    }
}

diag("Testing Simulation::DiscreteEvent $Simulation::DiscreteEvent::VERSION, Perl $], $^X");