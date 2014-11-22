#!perl

use Test::More;
use Env::Path;
use IPC::Run qw(start pump finish timeout);
use Net::NodeTransformator;
use Try::Tiny;
use File::Temp qw(tempdir);

plan skip_all => 'transformator is required for this test' unless Env::Path->PATH->Whence('transformator');

plan tests => 1;

my $tmpdir = tempdir;
my $sock = $tmpdir.'/socket';

my ($in, $out, $err);
my $server = start [ transformator => $sock ], \$in, \$out, \$err, timeout(10);

pump $server until $out =~ /server bound/;

diag $out;

my $client = Net::NodeTransformator->new($sock);

try {
	is $client->jade(<<EOT, { name => 'Peter' }) => '<span>Hi Peter!</span>';
span
  | Hi #{name}!
EOT
} catch {
	diag $_
};

$server->kill_kill;
finish $server;
unlink $sock;
rmdir $tmpdir;
