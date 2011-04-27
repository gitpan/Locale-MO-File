#!perl -T

use strict;
use warnings;

use Carp qw(confess);
use Data::Hexdumper qw(hexdump);
use English qw(-no_match_vars $OS_ERROR $INPUT_RECORD_SEPARATOR);
require IO::File;

use Test::More tests => 6 + 1;
use Test::NoWarnings;
use Test::Exception;
use Test::Differences;

BEGIN {
    require_ok('Locale::MO::File');
}

my @messages = (
    { msgid  => 'I2', msgstr => 'S2' },
    { msgid  => 'I1', msgstr => 'S1' },
);

my $filename = '10_simple_data.mo';

my $hex_dump = <<'EOT';
  0x0000 : 95 04 12 DE 00 00 00 00 00 00 00 02 00 00 00 1C : ................
  0x0010 : 00 00 00 2C 00 00 00 00 00 00 00 00 00 00 00 02 : ...,............
  0x0020 : 00 00 00 3C 00 00 00 02 00 00 00 3F 00 00 00 02 : ...<.......?....
  0x0030 : 00 00 00 42 00 00 00 02 00 00 00 45 49 31 00 49 : ...B.......EI1.I
  0x0040 : 32 00 53 31 00 53 32 00                         : 2.S1.S2.
EOT

lives_ok(
    sub {
        my $mo = Locale::MO::File->new();
        $mo->set_filename($filename);
        $mo->set_is_big_endian(1);
        $mo->set_messages(\@messages);
        $mo->write_file();
    },
    "write mo file $filename",
);

ok(
    -f $filename,
    "mo file $filename exists",
);

eq_or_diff(
    do {
        my $file_handle = IO::File->new($filename, '< :raw')
            or confess "Can not open $filename\n$OS_ERROR";
        local $INPUT_RECORD_SEPARATOR = ();
        hexdump <$file_handle>;
    },
    $hex_dump,
    'compare hex dump',
);

my $messages_result;
lives_ok(
    sub {
        my $mo = Locale::MO::File->new();
        $mo->set_filename($filename);
        $mo->read_file();
        $messages_result = $mo->get_messages();
    },
    "read mo $filename",
);

eq_or_diff(
    $messages_result,
    [
        { msgid  => 'I1', msgstr => 'S1' },
        { msgid  => 'I2', msgstr => 'S2' },
    ],
    'check messages',
);