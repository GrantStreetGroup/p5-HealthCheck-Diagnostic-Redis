# NAME

HealthCheck::Diagnostic::Redis - Check for Redis connectivity and operations in HealthCheck

# VERSION

version v0.0.5

# SYNOPSIS

    use HealthCheck::Diagnostic::Redis;

    # Just check that we can connect to a host, and get a random value back.
    HealthCheck::Diagnostic::Redis->check(
        host => 'redis.example.com',
    );

# DESCRIPTION

This Diagnostic will simply allow for an application to test for connectivity
to a Redis server, and additionally validate that it can successfully read keys
from that server.

# ATTRIBUTES

## name

A descriptive name for the connection test.
This gets populated in the resulting `info` tag.

## host

The server name to connect to for the test.
This is required.

## read\_only

Run a read-only check, instead of the read-and-write check provided
by-default.

## key\_name

Use a static key name instead of a randomly-generated one.

# DEPENDENCIES

[Redis::Fast](https://metacpan.org/pod/Redis%3A%3AFast)
[HealthCheck::Diagnostic](https://metacpan.org/pod/HealthCheck%3A%3ADiagnostic)

# CONFIGURATION AND ENVIRONMENT

None

# AUTHOR

Grant Street Group <developers@grantstreet.com>

# COPYRIGHT AND LICENSE

This software is Copyright (c) 2019 - 2020 by Grant Street Group.

This is free software, licensed under:

    The Artistic License 2.0 (GPL Compatible)
