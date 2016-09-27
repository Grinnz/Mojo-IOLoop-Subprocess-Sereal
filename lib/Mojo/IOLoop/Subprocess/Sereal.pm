package Mojo::IOLoop::Subprocess::Sereal;
use Mojo::Base 'Mojo::IOLoop::Subprocess';

use Exporter 'import';
use Scalar::Util 'weaken';
use Sereal::Decoder 'sereal_decode_with_object';
use Sereal::Encoder 'sereal_encode_with_object';

our $VERSION = '0.003';

our @EXPORT_OK = '$_subprocess';

my $deserializer = Sereal::Decoder->new;
my $deserialize = sub { sereal_decode_with_object $deserializer, $_[0] };
has deserialize => sub { $deserialize };

my $serializer = Sereal::Encoder->new({freeze_callbacks => 1});
my $serialize = sub { sereal_encode_with_object $serializer, $_[0] };
has serialize => sub { $serialize };

our $_subprocess = sub {
  my $ioloop = shift;
  my $subprocess = __PACKAGE__->new;
  weaken $subprocess->ioloop(ref $ioloop ? $ioloop : $ioloop->singleton)->{ioloop};
  return $subprocess->run(@_);
};

1;

=encoding utf8

=head1 NAME

Mojo::IOLoop::Subprocess::Sereal - Subprocesses with Sereal

=head1 SYNOPSIS

  use Mojo::IOLoop::Subprocess::Sereal;

  # Operation that would block the event loop for 5 seconds
  my $subprocess = Mojo::IOLoop::Subprocess::Sereal->new;
  $subprocess->run(
    sub {
      my $subprocess = shift;
      sleep 5;
      return '♥', 'Mojolicious';
    },
    sub {
      my ($subprocess, $err, @results) = @_;
      say "I $results[0] $results[1]!";
    }
  );

  # Start event loop if necessary
  $subprocess->ioloop->start unless $subprocess->ioloop->is_running;

  # Run from event loop (preferred)
  use Mojo::IOLoop::Subprocess::Sereal '$_subprocess';

  # Arguments passed along to $subprocess->run()
  my $subprocess = Mojo::IOLoop->$_subprocess(sub {...}, sub {...});

  # Start event loop if necessary
  Mojo::IOLoop->start unless Mojo::IOLoop->is_running;

=head1 DESCRIPTION

L<Mojo::IOLoop::Subprocess::Sereal> is a subclass of
L<Mojo::IOLoop::Subprocess> which uses L<Sereal> for data serialization.
L<Sereal> is faster than L<Storable> and supports serialization of more
reference types such as C<Regexp>. The
L<Sereal::Encoder/"FREEZE/THAW CALLBACK MECHANISM"> is supported to control
serialization of blessed objects.

A C<$_subprocess> method can be exported which works as a drop-in replacement
for L<Mojo::IOLoop/"subprocess"> while using L<Sereal> for data serialization.
This is the preferred interface to avoid memory leaks.

Note that L<Mojo::IOLoop::Subprocess> is EXPERIMENTAL and thus so is this
module!

=head1 ATTRIBUTES

L<Mojo::IOLoop::Subprocess::Sereal> inherits all attributes from
L<Mojo::IOLoop::Subprocess> and implements the following new ones.

=head2 deserialize

  my $cb      = $subprocess->deserialize;
  $subprocess = $subprocess->deserialize(sub {...});

A callback used to deserialize subprocess return values, defaults to using
L<Sereal::Decoder>.

  $subprocess->deserialize(sub {
    my $bytes = shift;
    return [];
  });

=head2 serialize

  my $cb      = $subprocess->serialize;
  $subprocess = $subprocess->serialize(sub {...});

A callback used to serialize subprocess return values, defaults to using
L<Sereal::Encoder>.

  $subprocess->serialize(sub {
    my $array = shift;
    return '';
  });

=head1 METHODS

L<Mojo::IOLoop::Subprocess::Sereal> inherits all methods from
L<Mojo::IOLoop::Subprocess>.

=head1 EXPORTS

L<Mojo::IOLoop::Subprocess::Sereal> exports the following variables.

=head2 $_subprocess

  my $subprocess = Mojo::IOLoop->$_subprocess(sub {...}, sub {...});
  my $subprocess = $loop->$_subprocess(sub {...}, sub {...});

Build L<Mojo::IOLoop::Subprocess::Sereal> object to perform computationally
expensive operations in subprocesses, without blocking the event loop.
Callbacks will be passed along to L<Mojo::IOLoop::Subprocess/"run">.

  # Operation that would block the event loop for 5 seconds
  Mojo::IOLoop->$_subprocess(
    sub {
      my $subprocess = shift;
      sleep 5;
      return '♥', 'Mojolicious';
    },
    sub {
      my ($subprocess, $err, @results) = @_;
      say "Subprocess error: $err" and return if $err;
      say "I $results[0] $results[1]!";
    }
  );

=head1 BUGS

Report any issues on the public bugtracker.

=head1 AUTHOR

Dan Book <dbook@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2016 by Dan Book.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=head1 SEE ALSO

L<Mojo::IOLoop>, L<Sereal>
