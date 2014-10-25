package HTML::CalendarMonth::fr;

use strict;
use Carp;

use vars qw(@ISA $VERSION);
$VERSION = '0.01';

use HTML::CalendarMonth::Lang;
@ISA = qw(HTML::CalendarMonth::Lang);

__PACKAGE__->register_days(qw(D L Ma Me J V S));

__PACKAGE__->register_months(
  qw(Janvier   F�vrier Mars     Avril
     Mai       Juin    Juillet  Ao�t
     Septembre Octobre Novembre D�cembre)
);

1;
