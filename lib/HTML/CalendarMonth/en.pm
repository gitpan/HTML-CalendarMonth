package HTML::CalendarMonth::en;

use strict;
use Carp;

use vars qw(@ISA $VERSION);
$VERSION = '0.01';

use HTML::CalendarMonth::Lang;
@ISA = qw(HTML::CalendarMonth::Lang);

__PACKAGE__->register_days(qw(Su M Tu W Th F Sa));

__PACKAGE__->register_months(
  qw(January   February March    April
     May       June     July     August
     September October  November December)
);

1;
