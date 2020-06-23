package HealthCheck::Diagnostic::Redis;

use strict;
use warnings;

use parent 'HealthCheck::Diagnostic';

use Carp;
use Redis::Fast;
use String::Random;

# ABSTRACT: Check for Redis connectivity and operations in HealthCheck
# VERSION

sub new {
    my ($class, @params) = @_;

    my %params = @params == 1 && ( ref $params[0] || '' ) eq 'HASH'
        ? %{ $params[0] } : @params;

    return $class->SUPER::new(
        id    => 'redis',
        label => 'redis',
        %params,
    );
}

sub check {
    my ($self, %params) = @_;
 
    # Allow the diagnostic to be called as a class as well.
    if ( ref $self ) {
        $params{$_} = $self->{$_}
            foreach grep { ! defined $params{$_} } keys %$self;
    }
 
    # The host is the only required parameter.
    croak "No host" unless $params{host};
 
    return $self->SUPER::check(%params);
}

sub run {
    my ($self, %params) = @_;

    my $host     = $params{host};

    my $name        = $params{name};
    my $description = $name ? "$name ($host) Redis" : "$host Redis";

    # Add on the port if need be.
    $host .= ':6379' unless $host =~ /:\d+$/;

    # Connect to the host...
    my $redis;
    local $@;
    eval {
        local $SIG{__DIE__};
        $redis = Redis::Fast->new(
            server => $host,

            # HealthCheck should not reconnect
            reconnect => 0,

            # Make this quick...
            cnx_timeout => 0.5,
            read_timeout => 0.5,
            write_timeout => 0.5,
        );
    };
    return {
        status => 'CRITICAL',
        info   => "Error for $description: $@",
    } if $@;

    unless ($redis->ping) {
        return {
            status  => 'CRITICAL',
            info    => "Error for $description: Redis ping failed",
        };
    }

    # Attempt to get a result from the readability or writeability
    # test.
    my $res = $params{read_only}
        ? $self->test_read_only( $redis, $description, %params )
        : $self->test_read_write( $redis, $description, %params );

    return $res if ref $res eq 'HASH';
    return {
        status => 'OK',
        info   => "Successful connection for $description",
    };
}

sub test_read_only {
    my ($self, $redis, $description, %params) = @_;

    my ($key, $error) = ($params{key_name}) || $redis->randomkey;
    return {
        status => 'CRITICAL',
        info   => sprintf( 'Error for %s: Failed getting random entry - %s',
            $description,
            $error,
        ),
    } if $error;

    # When there is no key, that means we don't have anything in the
    # database. No need to ping on that.
    return unless $key || $params{key_name};

    my $val = $redis->get( $key );
    return {
        status => 'CRITICAL',
        info   => sprintf( 'Error for %s: Failed reading value of key %s',
            $description,
            $key,
        ),
    } unless defined $val;
}

sub test_read_write {
    my ($self, $redis, $description, %params) = @_;
    my $key = $params{key_name} || sprintf(
        '_health_check_%s',
        String::Random->new->randregex('[A-Z0-9]{24}'),
    );

    # Do not overwrite anything in the database.
    return {
        status => 'CRITICAL',
        info   => sprintf( 'Error for %s: Cannot overwrite key %s',
            $description,
            $key,
        ),
    } if defined $redis->get( $key );

    # Set, get, and delete the temporary value.
    $redis->set( $key => 'temp' );
    my $val = $redis->get( $key );
    $redis->del( $key );

    return {
        status => 'CRITICAL',
        info   => sprintf( 'Error for %s: Failed writing to key %s',
            $description,
            $key,
        ),
    } unless defined $val;
}

1;
__END__

=head1 SYNOPSIS

    use HealthCheck::Diagnostic::Redis;

    # Just check that we can connect to a host, and get a random value back.
    HealthCheck::Diagnostic::Redis->check(
        host => 'redis.example.com',
    );

=head1 DESCRIPTION

This Diagnostic will simply allow for an application to test for connectivity
to a Redis server, and additionally validate that it can successfully read keys
from that server.

=head1 ATTRIBUTES

=head2 name

A descriptive name for the connection test.
This gets populated in the resulting C<info> tag.

=head2 host

The server name to connect to for the test.
This is required.

=head2 read_only

Run a read-only check, instead of the read-and-write check provided
by-default.

=head2 key_name

Use a static key name instead of a randomly-generated one.

=head1 DEPENDENCIES

L<Redis::Fast>
L<HealthCheck::Diagnostic>

=head1 CONFIGURATION AND ENVIRONMENT

None

