#!perl -T

use strict;
use warnings;

use Carp qw(confess);
use English qw(-no_match_vars $OS_ERROR $INPUT_RECORD_SEPARATOR);
use Hash::Util qw(lock_hash);
use IO::File qw(SEEK_SET);

use Test::More tests => 9 + 1;
use Test::NoWarnings;
use Test::Differences;
use Test::Exception;
use Test::HexDifferences;

BEGIN {
    require_ok('Locale::MO::File');
}

my @messages = (
    {
        msgid  => q{},
        msgstr => <<'EOT',
MIME-Version: 1.0
Content-Type: text/plain; charset=ISO-8859-1
Plural-Forms: nplurals=2; plural=n != 1
EOT
    },
    {
        msgid  => 'original',
        msgstr => 'translated',
    },
    {
        msgctxt => 'context',
        msgid   => 'c_original',
        msgstr  => 'c_translated',
    },
    {
        msgid         => 'o_singular',
        msgid_plural  => 'o_plural',
        msgstr_plural => [ qw(t_singular t_plural) ],
    },
    {
        msgctxt       => 'c_context',
        msgid         => 'c_o_singular',
        msgid_plural  => 'c_o_plural',
        msgstr_plural => [ qw(c_t_singular c_t_plural) ],
    },
);
for my $message (@messages) {
    lock_hash %{$message};
}

my $filename = '12_big_endian.mo';

my @sorted_messages = (
    map {
        $_->[0];
    }
    sort {
        $a->[1] cmp $b->[1];
    }
    map {
        [
            $_,
            Locale::MO::File->new(filename => $filename)->_pack_message($_)->{msgid},
        ];
    } @messages
);

my $hex_dump = <<'EOT';
0000 : 95 04 12 DE 00 00 00 00 00 00 00 05 00 00 00 1C : ................
0010 : 00 00 00 44 00 00 00 00 00 00 00 00 00 00 00 00 : ...D............
0020 : 00 00 00 6C 00 00 00 21 00 00 00 6D 00 00 00 12 : ...l...!...m....
0030 : 00 00 00 8F 00 00 00 13 00 00 00 A2 00 00 00 08 : ................
0040 : 00 00 00 B6 00 00 00 67 00 00 00 BF 00 00 00 17 : .......g........
0050 : 00 00 01 27 00 00 00 0C 00 00 01 3F 00 00 00 13 : ...........?....
0060 : 00 00 01 4C 00 00 00 0A 00 00 01 60 00 63 5F 63 : ...L.......`.c_c
0070 : 6F 6E 74 65 78 74 04 63 5F 6F 5F 73 69 6E 67 75 : ontext.c_o_singu
0080 : 6C 61 72 00 63 5F 6F 5F 70 6C 75 72 61 6C 00 63 : lar.c_o_plural.c
0090 : 6F 6E 74 65 78 74 04 63 5F 6F 72 69 67 69 6E 61 : ontext.c_origina
00A0 : 6C 00 6F 5F 73 69 6E 67 75 6C 61 72 00 6F 5F 70 : l.o_singular.o_p
00B0 : 6C 75 72 61 6C 00 6F 72 69 67 69 6E 61 6C 00 4D : lural.original.M
00C0 : 49 4D 45 2D 56 65 72 73 69 6F 6E 3A 20 31 2E 30 : IME-Version:.1.0
00D0 : 0A 43 6F 6E 74 65 6E 74 2D 54 79 70 65 3A 20 74 : .Content-Type:.t
00E0 : 65 78 74 2F 70 6C 61 69 6E 3B 20 63 68 61 72 73 : ext/plain;.chars
00F0 : 65 74 3D 49 53 4F 2D 38 38 35 39 2D 31 0A 50 6C : et=ISO-8859-1.Pl
0100 : 75 72 61 6C 2D 46 6F 72 6D 73 3A 20 6E 70 6C 75 : ural-Forms:.nplu
0110 : 72 61 6C 73 3D 32 3B 20 70 6C 75 72 61 6C 3D 6E : rals=2;.plural=n
0120 : 20 21 3D 20 31 0A 00 63 5F 74 5F 73 69 6E 67 75 : .!=.1..c_t_singu
0130 : 6C 61 72 00 63 5F 74 5F 70 6C 75 72 61 6C 00 63 : lar.c_t_plural.c
0140 : 5F 74 72 61 6E 73 6C 61 74 65 64 00 74 5F 73 69 : _translated.t_si
0150 : 6E 67 75 6C 61 72 00 74 5F 70 6C 75 72 61 6C 00 : ngular.t_plural.
0160 : 74 72 61 6E 73 6C 61 74 65 64 00                : translated.
EOT

# === file ===

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

dumped_eq_dump_or_diff(
    do {
        my $file_handle = IO::File->new($filename, '< :raw')
            or confess "Can not open $filename\n$OS_ERROR";
        local $INPUT_RECORD_SEPARATOR = ();
        <$file_handle>;
    },
    $hex_dump,
    { format => "%a : %16C : %d\n%*x" },
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
    \@sorted_messages,
    'check messages',
);

# === file handle ===

$filename =~ s{[.]}{_fh.}xms;

my $file_handle = IO::File->new($filename, '+> :raw')
    or confess "Can not open $filename\n$OS_ERROR";

lives_ok(
    sub {
        my $mo = Locale::MO::File->new();
        $mo->set_filename($filename);
        $mo->set_file_handle($file_handle);
        $mo->set_is_big_endian(1);
        $mo->set_messages(\@messages);
        $mo->write_file();
    },
    "using open file handle: write mo file $filename",
);

$file_handle->seek(0, SEEK_SET)
    or confess "Can not seek $filename\n$OS_ERROR";

$messages_result = ();
lives_ok(
    sub {
        my $mo = Locale::MO::File->new();
        $mo->set_filename($filename);
        $mo->set_file_handle($file_handle);
        $mo->read_file();
        $messages_result = $mo->get_messages();
    },
    "using open file handle: read mo file $filename",
);

eq_or_diff(
    $messages_result,
    \@sorted_messages,
    'using open file handle: check messages',
);

$file_handle->close()
    or confess "Can not close $filename\n$OS_ERROR";
