package Color::Output;

use warnings;
use strict;
use Carp;

our $VERSION = 1.01;


BEGIN {
  use Exporter   ();
  our (@ISA, @EXPORT);

  @ISA = qw(Exporter);
  @EXPORT = qw(&DoPrint &Clear);
}

my ($Clear, $Mode, $Method, $Console, @List);


sub new  {
  my $self  = { } ;
  bless ($self);

  if (defined $_[1] and $_[1] =~ /^\d+$/) {
    if ($_[1] == 1) { $self->Init_ANSI; }
    elsif ($_[1] == 2) { $self->Init_W32Console; }
  }
  unless (defined $Method) {
    if ($^O =~ /Win32/) { 
      $self->Init_W32Console;
      $Clear = 'cls';
    }
    else { 
      $self->Init_ANSI;
      $Clear = 'clear';
    }
  }
  return $self;
}


sub Init_W32Console {
  $Method = \&Print_Console;
  $Mode = 2;

  require Win32::Console;
  $Console = new Win32::Console;

  @List = qw(7 0 1 9 4 12 2 10 5 13 3 11 6 14 7 15);
}

sub Init_ANSI {
  $Method = \&Print_ANSI;
  $Mode = 1;

  @List = qw(0m 30m 34m 34;1m 31m 31;1m 32m 32;1m 35m 35;1m 36m 36;1m 33m 33;1m 37m 37;1m);
}


sub Clear {
  croak "You did not initialised this module with the new-method!", unless (defined $Clear and defined $Mode);

  if ($Mode == 1) { system($Clear); }
  else {
    $Console->Cls;
    $Console->Display;
  }
}


sub DoPrint {
  croak "You did not initialised this module with the new-method!", unless (defined $Method);
  &$Method(@_);
}

sub Print_Console {
  my ($String) = shift;
  return, unless (defined $String);

  $String =~ s/\x03([\s\D])/\x030$1/g;
  my ($First) = $String =~ /^(.*?)\x03/s;
  $Console->Write($First), if (defined $First);

  while ($String =~ /\x03(\d\d?)([^\x03]*)/g) {
    $Console->Attr($List[$1]);
    $Console->Write($2);
  }
  $Console->Display;
}


sub Print_ANSI {
  my ($String) = shift;
  return, unless (defined $String);

  $String =~ s/\x03([\s\D])/\x030$1/g;
  $String =~ s/\x03(\d\d?)/\033[$List[$1]/g;

  print $String;
}

END {
  if (defined $Mode) {
    if ($Mode == 1) { printf "\033[" . $List[0]; }
  }
}

1;
__END__

=head1 NAME

Color::Output - Module to give color to the output

=head1 DESCRIPTION

With this module you can color the output. It will color the output on both Windows and on Unix/Linux.
On Windows it uses by default Win32::Console (unless overwritten with some options),
on Unix/Linux it uses ANSI by default.

This module allows you to do:

=over

=item *

Color the output of your program

=item *

Clearing the screen

=back

=head2 Methods

=over

=item new [Mode]

Initialise this module.
The mode can be (this mode applies to all systems):

=over

=item 1:

Use ANSI-colors

=item 2:

Use Win32::Console

=back

Examples:

   new Color::Output;      # Default mode, ANSI on Unix/Linux, Win32::Console on Windows
   new Color::Output (1);  # Use ANSI-colors
   new Color::Output (2);  # Use Win32::Console

=item DoPrint [Text]

Display the text on the screen. The char to identify a color is: \x03 or \003 or chr(3)

Examples:

   DoPrint ("\x033Blue text\x030\n");
   DoPrint ("\0035Red text\n");
   DoPrint ("The text is still red, ". chr(3) ."7and now it is green.\x030\n");

Note:

   The text-color is set to the default one when the program ends.

=item Clear

Clears the screen.

Example:

   Clear

=head1 Demo

  use Color::Output;
  new Color::Output;
  for (my($i)=0;$i<16;$i++) {
    DoPrint("Demo $i: \t\x03$i example\x030\n");
  }


=head1 NOTES

=over

=item *

If you use Win32::Console then the screen will be cleared before the text is displayed.
There is nothing I/you can do about that..

=item *

There is a module called Win32::Console::ANSI, but when I tested it had some bugs..
Therefor I decided to rewrite this module and make it public.

=item *

When Win32::Console is used then a normal print/printf won't be visibile.

=back

=head1 SEE ALSO

=over

=item *

  Term::ANSIColor

=item *

  Win32::Console

=item *

  Win32::Console::ANSI

=back

=head1 BUGS

None reported so far

=head1 AUTHOR

Animator <Animator@CQ-Empires.com>

=head1 COPYRIGHT

Copyright (c) 2003 Animator. All rights reserved.

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.
