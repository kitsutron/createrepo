# @summary Repository management resource for createrepo
#
# Creates and manages local software repositories using createrepo.
#
# @param auto_refresh
#   Whether to refresh the repository automatically using cron.
#
# @param refresh_period
#   The cron time signature for automatically refreshing the repository.
#   Follows standard cron time format. Defaults to every 5 minutes.
#
# @param timeout
#   Timeout in seconds for createrepo.
#   Createrepo will continue to attempt repository creation until it hits the timeout, in which case it will error.
#   Defaults to 5 minutes (300 seconds).
#
# @example
#   createrepo::repo {'example': }
#
#   createrepo::repo {'example_b':
#     timeout => 500,
#   }
define createrepo::repo (
  Boolean   $auto_refresh   = true,
  String[1] $refresh_period = '*/5 * * * * *',
  Integer   $timeout        = 300,
) {
  file { "${createrepo::params::repo_base}/${name}":
    ensure => directory,
    owner  => $createrepo::params::repo_owner,
    group  => $createrepo::params::repo_group,
    mode   => '0750',
  }

  exec { "Create repo for ${name}":
    command => "${createrepo::params::createrepo_new} ${createrepo::params::repo_base}/${name}",
    user    => $createrepo::params::repo_owner,
    group   => $createrepo::params::repo_group,
    creates => "${createrepo::params::repo_base}/${name}/repodata",
    timeout => $timeout,
  }

  file { "/etc/cron.d/99createrepo_${name}":
    ensure  => file,
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    content => epp('createrepo/repo_cron.epp', {
        cron                      => $refresh_period,
        createrepo_update_command => $createrepo::params::createrepo_update,
        repo_group                => $createrepo::params::repo_group,
        repo_owner                => $createrepo::params::repo_owner,
        repo_path                 => "${createrepo::params::repo_base}/${name}",
    }),
  }

  if $createrepo::params::install_webserver {
    file { "${createrepo::params::apache_conf_dir}/sites-available/${name}.conf":
      ensure  => file,
      owner   => $createrepo::params::repo_owner,
      group   => $createrepo::params::repo_group,
      mode    => '0644',
      content => epp('createrepo/apache_vhost.epp', {
          server_name  => "${name}.${trusted['certname']}",
          server_alias => "${name}.${trusted['certname']}",
          repo_path    => "${createrepo::params::repo_base}/${name}",
      }),
    }

    file { "${createrepo::params::apache_conf_dir}/sites-enabled/${name}.conf":
      ensure => link,
      target => "${createrepo::params::apache_conf_dir}/sites-available/${name}.conf",
    }
  }

  File[
    "${createrepo::params::apache_conf_dir}/sites-available/${name}.conf",
    "${createrepo::params::apache_conf_dir}/sites-enabled/${name}.conf"
  ] -> Service["${createrepo::params::apache_service_name}"]
}
