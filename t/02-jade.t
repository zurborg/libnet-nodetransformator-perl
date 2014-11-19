#!perl

use Test::More;
use Env::Path;
use IPC::Run qw(start pump finish timeout);
use Net::NodeTransformator;
use Try::Tiny;

plan skip_all => 'transformator is required for this test' unless Env::Path->PATH->Whence('transformator');

plan tests => 1;

my $sock = './socket';
unlink $sock if -e $sock;

my ($in, $out, $err);
my $server = start [ transformator => $sock ], \$in, \$out, \$err, timeout(10);

pump $server until $out =~ /server bound/;

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

