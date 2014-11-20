package Net::NodeTransformator;

use strict;
use warnings;
use AnyEvent;
use AnyEvent::Handle;
use AnyEvent::Socket;
use POSIX qw(getcwd);

=head1 NAME

Net::NodeTransformator - interface to node transformator

=head1 VERSION

Version 0.101

=cut

our $VERSION = '0.101';

=head1 SYNOPSIS

	use Net::NodeTransformator;
	
	my $nnt = Net::NodeTransformator->new;
	
	my $jade_in = <<'EOT';
	span
	  | Hi #{name}!
	EOT
	
	my $jade_vars = {
		name => 'Peter'
	};
	
	my $jade_out = $nnt->jade($jade_in, $jade_vars);

=head1 DESCRIPTION

This module is an interface to the transformator package of nodejs. See L<https://www.npmjs.org/package/transformator> for more information about the server.

When it's difficult for perl to interact with various nodejs packages, the transformator protocol allows everyone to interact with an nodejs service. transformator supports a vast range of libraries like jade-lang, sass-lang or coffeescript.

The other way is to invoke each command-line tool as a child process, but this may be very inefficient if such tool need to be called frequently.

=head1 METHODS

=head2 new($hostport)

Set the hostname/port or unix domain socket for connecting to transformator.

	Net::NodeTransformator->new('12345');
	Net::NodeTransformator->new('localhost:12345');
	Net::NodeTransformator->new('path/to/unix/domain/socket');	

=cut

sub new {
	my ($class, $hostport) = @_;
	if ($hostport !~ m{:}) {
		if ($hostport =~ m{^\d+$}) {
			$hostport = "localhost:$hostport";
		} else {
			$hostport = "unix/:$hostport";
		}
	}
	my ($host, $port) = parse_hostport($hostport);
	if ($host eq 'unix/' and $port !~ m{^/}) {
		$port = getcwd.'/'.$port;
	}
	bless {
		host => $host,
		port => $port,
	} => ref $class || $class;
}

=head2 transform_cv(%options)

Connects to transformator and waits for the result asynchronously by using a condition variable.

%options requires for keyworks:

=over 4

=item C<engine> The engine to be used

=item C<input> The input string

=item C<data> (optional) Additional data to be send with. Currently only meaningful for I<jade> engine.

=item C<on_error> A callback subroutine called in case of any error

=back

This method returns a condition variable (L<AnyEvent>->condvar)

	my $cv = $nnt->transform_cv(...);

The result will be pushed to the condvar, so C<$cv->recv> will return the result.

=cut

sub transform_cv($%) {
	my ($self, %options) = @_;
	
	my $cv = AE::cv;
	
	my $err = sub {
		$options{on_error}->(@_);
		$cv->send(undef);
	};

	my $host = $self->{host};
	my $port = $self->{port};

	tcp_connect ($host, $port, sub {
		return $err->("Connect to $host:$port failed: $!") unless @_;
		my ($fh) = @_;
		my $AEH;
		$AEH = AnyEvent::Handle->new(
			fh => $fh,
			on_error => sub {
				my ($handle, $fatal, $message) = @_;
				$handle->destroy;
				$err->("Socket error: $message");
			},
			on_eof => sub {
				$AEH->destroy;
			},
		);
		$AEH->push_read(cbor => sub {
			my $answer = $_[1];
			if (defined $answer and ref $answer eq 'HASH') {
				if (exists $answer->{error}) {
					$err->("Service error: ".$answer->{error});
				} elsif (exists $answer->{result}) {
					$cv->send($answer->{result});
				} else {
					$err->("Something is wrong: no result and no error");
				}
			} else {
				$err->("No answer");
			}
		});
		$AEH->push_write(cbor => [ $options{engine}, $options{input}, $options{data} || {} ]);
	});
	$cv;
}

=head2 transform($engine, $input, $data)

This is the synchronous variant of C<transform_cv>. It croaks on error and can be catched by L<Try::Tiny> for example.

=cut

sub transform($$$;$) {
	my ($self, $engine, $input, $data) = @_;
	my $error;
	my $result = $self->transform_cv(
		on_error => sub { $error = shift },
		engine => $engine,
		input => $input,
		data => $data,
	)->recv;
	return $result if defined $result and not defined $error and not ref $result;
	if (not defined $result and defined $error) {
		AE::log error => $error;
	} else {
		AE::log error => "Something is wrong: $@";
	}
}

=head1 SHORTCUT METHODS

This list is incomplete. I will add more methods on request. All methods are hopefully self-describing.

=head2 jade($input, $data)

=cut

sub jade            ($$;$) { shift->transform(jade         => @_) }

=head2 coffeescript($input)

=cut

sub coffeescript    ($$;$) { shift->transform(coffeescript => @_) }

=head2 minify_html($input)

=cut

sub minify_html     ($$;$) { shift->transform(minify_html  => @_) }

=head2 minify_css($input)

=cut

sub minify_css      ($$;$) { shift->transform(minify_css   => @_) }

=head2 minify_js($input)

=cut

sub minify_js       ($$;$) { shift->transform(minify_js    => @_) }

=head1 AUTHOR

David Zurborg, C<< <zurborg@cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests at L<https://github.com/zurborg/libnet-nodetransformator-perl/issues>. I
will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Net::NodeTransformator

You can also look for information at:

=over 4

=item * GitHub: Public repository of this module

L<https://github.com/zurborg/libnet-nodetransformator-perl>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Net-NodeTransformator>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Net-NodeTransformator>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Net-NodeTransformator>

=item * Search CPAN

L<http://search.cpan.org/dist/Net-NodeTransformator/>

=back

=head1 COPYRIGHT & LICENSE

Copyright 2014 David Zurborg, all rights reserved.

This program is released under the ISC license.

=cut

1;
