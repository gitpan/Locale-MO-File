use strict;
use warnings;

use Module::Build;

Module::Build->new(
    module_name       => 'Locale::MO::File',
    license           => 'perl',
    dist_abstract     => 'Locale::MO::File - Write or read gettext MO files.',
    dist_author       => 'Steffen Winkler <steffenw at cpan.org>',
    dist_version_from => 'lib/Locale/MO/File.pm',
    requires          => {
        perl                        => '5.006',
        'Const::Fast'               => 0,
        Encode                      => 0, # Perl dist
        English                     => 0, # Perl dist
        'IO::File'                  => 0, # Perl dist
        Moose                       => 0,
        'MooseX::StrictConstructor' => 0,
        'namespace::autoclean'      => 0,
        'Params::Validate'          => 0,
    },
    build_requires => {
        'Hash::Util'           => 0,
        'Test::Differences'    => 0,
        'Test::Exception'      => 0,
        'Test::HexDifferences' => 0,
        'Test::More'           => 0, # dist Test-Simple
        'Test::NoWarnings'     => 0,
    },
    recommends => {
        # build
        'Test::Pod'           => '1.14',
        'Test::Pod::Coverage' => '1.04',
    },
    create_makefile_pl   => 'traditional',
    recursive_test_files => 0,
    add_to_cleanup       => [ qw(
        META.yml *.bak *.gz Makefile.PL *.mo
    ) ],
)->create_build_script;
