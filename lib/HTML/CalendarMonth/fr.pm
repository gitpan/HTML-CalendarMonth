package HTML::CalendarMonth::fr;

use strict;
use Carp;

use vars qw(@ISA $VERSION);
$VERSION = '0.01';

use HTML::CalendarMonth::Lang;
@ISA = qw(HTML::CalendarMonth::Lang);

__PACKAGE__->register_days(qw(D L Ma Me J V S));

__PACKAGE__->register_months(
  qw(Janvier   Février Mars     Avril
     Mai       Juin    Juillet  Août
     Septembre Octobre Novembre Décembre)
);

1;
