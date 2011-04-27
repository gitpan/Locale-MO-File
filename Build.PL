use strict;
use warnings;

use Module::Build;

my $is_ppm
    = (
        # install using ppm
        ! $ENV{AUTHOR_DIST}
        && eval 'require ActivePerl::PPM::Package'
    )
    || (
        # build ppm and ppd
        $ENV{AUTHOR_DIST}
        && $ENV{AUTHOR_DIST} eq 'ppm'
    );

Module::Build->new(
    module_name       => 'Locale::MO::File',
    license           => 'perl',
    dist_abstract     => 'Locale::MO::File - Write or read gettext MO files.',
    dist_author       => 'Steffen Winkler <steffenw at cpan.org>',
    dist_version_from => 'lib/Locale/MO/File.pm',
    requires          => {
        perl                        => '5.006',
        Moose                       => 0,
        'MooseX::StrictConstructor' => 0,
        'MooseX::FollowPBP'         => 0,
        'Params::Validate'          => 0,
        Readonly                    => 0,
        $is_ppm
        ? ()
        : (
            Carp       => 0,
            English    => 0,
            Encode     => 0,
            'IO::File' => 0,
        )
    },
    build_requires => {
        'Test::NoWarnings'  => 0,
        'Test::Exception'   => 0,
        'Test::Differences' => 0,
        'Hash::Util'        => 0,
        'Data::Hexdumper'   => 0,
        $is_ppm
        ? (
            'Test::Simple' => 0,
        )
        : (
            'Test::More' => 0, # dist Test-Simple
        )
    },
    recommends => {
        # build
        'Test::Pod'           => '1.14',
        'Test::Pod::Coverage' => '1.04',
    },
    create_makefile_pl   => 'traditional',
    recursive_test_files => 1,
    add_to_cleanup       => [ qw(
        META.yml *.bak *.gz Makefile.PL *.mo
    ) ],
)->create_build_script();