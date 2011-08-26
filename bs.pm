package bs;

use Moose;
with 'Dist::Zilla::Role::VersionProvider';
with 'Dist::Zilla::Role::ModuleInfo';

sub provide_version {
  my ($self) = @_;

  my $main_module = $self->zilla->main_module;
  my $module = $main_module->name;

  my $pm_info = $self->get_module_info($main_module);
  my $ver     = $pm_info->version;

  die "Unable to get version from $module" unless defined $ver;

  $self->log("dist version $ver (from $module)");

  "$ver";
}

1;
