# @summary Parameter class for inheritance by other module classes.
#
# This class sets necessary parameters for other classes in the module. Do not include this module directly.
#
# @param install_webserver
#   Whether to install httpd automatically along with createrepo.
#   This will configure repositories under /var/www/html/repos/ by default instead of /var/repos/.
#
# @param create_default_vhost
#   Whether or not to create a default vhost for httpd.
#   This prevents apache serving the first repo when a requested vhost doesn't exist.
#
# @example
#   include createrepo::params
#
class createrepo::params (
  Boolean $install_webserver    = true,
  Boolean $create_default_vhost = true,
) {
  case $install_webserver {
    true: {
      $repo_base = '/var/www/html/repos'
      $repo_dirs = ['/var/www','/var/www/html','/var/www/html/repos']
      $repo_owner = 'apache'
      $repo_group = 'apache'
    }
    default: {
      $repo_base = '/var/repos'
      $repo_dirs = ['/var/repos']
      $repo_owner = 'root'
      $repo_group = 'root'
    }
  }

  case $facts['os']['family'] {
    'RedHat': {
      case $facts['os']['distro']['id'] {
        default: {
          $createrepo_package  = 'createrepo'
          $createrepo_command  = '/bin/createrepo'
          $apache_conf_dir     = '/etc/httpd'
          $apache_conf_file    = '/etc/httpd/conf/httpd.conf'
          $apache_service_name = 'httpd'
        }
        'Rocky': {
          $createrepo_package  = 'createrepo_c'
          $createrepo_command  = '/bin/createrepo_c'
          $apache_conf_dir     = '/etc/httpd'
          $apache_conf_file    = '/etc/httpd/conf/httpd.conf'
          $apache_service_name = 'httpd'
        }
      }

      $createrepo_new = "${createrepo_command} --database"
      $createrepo_update = "${createrepo_command} --update"
    }
    default: { fail("Module ${module_name} does not support ${facts['os']['release']['full']}.") }
  }
}
