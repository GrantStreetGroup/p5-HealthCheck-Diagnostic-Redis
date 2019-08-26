use strict;
use warnings;

use Test::More;

BEGIN { use_ok('HealthCheck::Diagnostic::Redis') };

diag(qq(HealthCheck::Diagnostic::Redis Perl $], $^X));

done_testing;
