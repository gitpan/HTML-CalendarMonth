package HTML::CalendarMonth::de;

use strict;
use Carp;

use vars qw(@ISA $VERSION);
$VERSION = '0.01';

use HTML::CalendarMonth::Lang;
@ISA = qw(HTML::CalendarMonth::Lang);

__PACKAGE__->register_days(qw(So Mo Di Mi Do Fr Sa));

__PACKAGE__->register_months(
  qw(Januar    Februar März     April
     Mai       Juni    Juli     August
     September Oktober November Dezember)
);

1;
