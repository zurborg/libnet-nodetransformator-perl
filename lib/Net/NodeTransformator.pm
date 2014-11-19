package Net::NodeTransformator;

use strict;
use warnings;
use AnyEvent;
use AnyEvent::Handle;
use AnyEvent::Socket;
use Carp;

=head1 NAME

Net::NodeTransformator - interface to node transformator

=head1 VERSION

Version 0.100

=cut

our $VERSION = '0.100';

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

...

=head1 METHODS

=head2 new($hostport)

=cut

sub new {
	my ($class, $hostport) = @_;
	my ($host, $port) = parse_hostport($hostport);
	bless {
		host => $host,
		port => $port,
	} => ref $class || $class;
}

=head2 transform_cv(%options)

=cut

sub transform_cv($%) {
	my ($self, %options) = @_;
	
	my $cv = AE::cv;
	
	my $err = sub {
		$options{on_error}->(@_);
		$cv->send(undef);
	};
	
	tcp_connect ($self->{host}, $self->{port}, sub {
		return $err->($!) unless @_;
		my ($fh) = @_;
		my $AEH;
		$AEH = AnyEvent::Handle->new(
			fh => $fh,
			on_error => sub {
				shift->destroy;
				$err->($@);
			},
			on_eof => sub {
				$AEH->destroy;
			},
		);
		$AEH->push_read(cbor => sub {
			my $answer = $_[1];
			if (defined $answer and ref $answer eq 'HASH') {
				if (exists $answer->{error}) {
					$err->($answer->{error});
				} elsif (exists $answer->{result}) {
					$cv->send($answer->{result});
				} else {
					$err->("Something is wrong: no result and no error ($@)");
				}
			} else {
				$err->("No answer ($@)");
			}
		});
		$AEH->push_write(cbor => [ $options{engine}, $options{input}, $options{data} || {} ]);
	});
	$cv;
}

=head2 transform($engine, $input, $data)

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
		croak $error;
	} else {
		croak "Something is wrong: $@";
	}
}

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
