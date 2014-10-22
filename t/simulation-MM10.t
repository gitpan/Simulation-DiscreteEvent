use strict;
use warnings;

use Test::More qw(no_plan);

use ok 'Simulation::DiscreteEvent';

{
    package Test::DE::Generator;
    use parent 'Simulation::DiscreteEvent::Server';
    use Moose;

    has rate => ( is => 'rw', isa => 'Num', default => 0.7 );
    has dst => ( is => 'rw', isa => 'Simulation::DiscreteEvent::Server' );
    has limit => ( is => 'rw', isa => 'Num', default => '1000' );

    sub next : Event(next) {
        my $self = shift;
        $self->model->send($self->dst, 'customer_new');
        my $limit = $self->limit - 1;
        return unless $limit;
        $self->limit($limit);
        my $next_time = $self->model->time - log(rand) / $self->rate;
        $self->model->schedule($next_time, $self, 'next');
    }
}

{
    package Test::DE::Server;
    use parent 'Simulation::DiscreteEvent::Server';
    use Moose;

    has rate => ( is => 'rw', isa => 'Num', default => 1 );
    has served => ( is => 'rw', isa => 'Num', default => 0 );
    has rejected => ( is => 'rw', isa => 'Num', default => 0 );
    has busy => ( is => 'rw', isa => 'Bool' );

    sub cust_new : Event(customer_new) {
        my $self = shift;
        if($self->busy) {
            $self->rejected($self->rejected + 1);
        }
        else {
            $self->busy(1);
            my $end_time = $self->model->time - log(rand) / $self->rate;
            $self->model->schedule($end_time, $self, 'customer_served');
        }
    }

    sub cust_served : Event(customer_served) {
        my $self = shift;
        $self->served($self->served + 1);
        $self->busy(0);
    }
}

my $model = Simulation::DiscreteEvent->new;

# add server to model
my $server = $model->add('Test::DE::Server');
is $server->model, $model, "Server's model is correct";

# add customers generator to model
my $generator = $model->add('Test::DE::Generator', rate => 1, dst => $server, limit => 10000 );
is $generator->rate, 1, "Generator rate is 1";

# generate first customer
$generator->next;
is 0+@{$model->events}, 2, "Two events scheduled";

# run simulation
$model->run;

is $server->served + $server->rejected, 10000, "Sum of customers is 10000";
ok $server->served < 5500, "About half of customers were served";
ok $server->rejected < 5500, "About half of customers were rejected";
ok $model->time > 7000, "Model time is greater than 7000";

=pod

print "Customers served: ", $server->served, "\n";
print "Customers rejected: ", $server->rejected, "\n";
print "Model time: ", $model->time, "\n";

=cut
