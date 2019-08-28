use GSG::Gitc::CPANfile $_environment;

# Add your requirements here
requires 'HealthCheck::Diagnostic';
requires 'Redis::Fast';

test_requires 'Test::MockModule';

on develop => sub {
    requires 'Dist::Zilla::PluginBundle::Author::GSG::Internal';
};
