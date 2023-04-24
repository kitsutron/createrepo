# @summary Createrepo module entry point.
#
# Installs requisite packages and creates the base path under which software
# repositories will be created.
#
# @param repos
#   A hash of repositories to create
#
# @example
#   class { createrepo:
#     repos       => {
#       example   => {},
#       exampler  => {},
#       examplest => {timeout => 400},
#     }
#   }
class createrepo (
  Hash $repos = {},
) inherits createrepo::params {
  # Ensure dependencies with Puppet stdlib function to reduce the incidence of
  # redeclaration collisions.
  ensure_packages('yum-utils')

  package { $createrepo::params::createrepo_package: ensure => present }

  if $createrepo::params::install_webserver {
    package { 'httpd': ensure => present }

    file { ["${createrepo::params::apache_conf_dir}/sites-available","${createrepo::params::apache_conf_dir}/sites-enabled"]:
      ensure => directory,
      owner  => 'root',
      group  => 'root',
      mode   => '0755',
    }

    file_line { 'sites_enabled_path':
      path => $createrepo::params::apache_conf_file,
      line => 'IncludeOptional sites-enabled/*.conf',
    }

    if $createrepo::params::create_default_vhost {
      file {
        default:
          owner => $createrepo::params::repo_owner,
          group => $createrepo::params::repo_group,
          ;
        "${createrepo::params::apache_conf_dir}/default":
          ensure => directory,
          mode   => '0755',
          ;
        "${createrepo::params::apache_conf_dir}/sites-available/00default.conf":
          ensure  => file,
          mode    => '0644',
          content => epp('createrepo/apache_vhost.epp', {
              server_name  => $trusted['certname'],
              server_alias => $trusted['certname'],
              repo_path    => "${createrepo::params::repo_base}/default",
          }),
          ;
        "${createrepo::params::apache_conf_dir}/sites-enabled/00default.conf":
          ensure => link,
          target => "${createrepo::params::apache_conf_dir}/sites-available/00default.conf",
          ;
      }
    }

    service { 'httpd':
      ensure => running,
      enable => true,
    }
  }

  file { $createrepo::params::repo_dirs:
    ensure => directory,
    owner  => $createrepo::params::repo_owner,
    group  => $createrepo::params::repo_group,
    mode   => '0750',
  }

  create_resources(createrepo::repo, $repos)

  File[
    "${createrepo::params::apache_conf_dir}/sites-available/00default.conf",
    "${createrepo::params::apache_conf_dir}/sites-enabled/00default.conf"
  ] -> Service['httpd']
}
