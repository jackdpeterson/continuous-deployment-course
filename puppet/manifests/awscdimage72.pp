include stdlib

stage { 'first':
  before => Stage['main']
}
stage { 'last':
}
Stage['main'] -> Stage['last']

swap_file::files { 'swapfile':
  ensure   => present,
  swapfile => '/swapfile',
  cmd      => 'fallocate',
}

package { 'mysql-client-core-5.7': ensure => present }

package { 'supervisor': ensure => present }

package { 'ruby': ensure => present }

include apt

apt::key { 'ruby-ng':
  id     => '80F70E11F0F0D5F10CB20E62F5DA5F09C3173AA6',
  server => 'keyserver.ubuntu.com'
}

package { 'gdebi': ensure => present }

class { 'awscli':
  version => '1.14.23',
  require => [Package['ruby']]
}

# # CodeDeployClient IAM User is attached via IAM role ##

file { '/usr/bin/aws':
  ensure => 'link',
  target => '/usr/local/bin/aws',
  owner  => 'root',

  group  => 'root',
  mode   => '0755'
}

class { 'codedeploy':
  require => [File['/usr/bin/aws'], Package['gdebi'], Package['ruby']]
}

# # Non-Local stuff ##

# # End of Non-Local (monitored) stuff ##


$packages = ['nano', 'git', 'mercurial', 'lynx', 'htop']

package { $packages: ensure => 'installed' }

/**
$auth_json = "{
    \"github-oauth\": {
        \"github.com\": \"YOUR_KEY_GOES_HERE\"
    }
}
"

file { '/var/www/.composer/':
  ensure => directory,
  owner  => 'www-data',
  mode   => '0755',
  group  => 'www-data',
}

file { '/var/www/.composer/auth.json':
  ensure  => present,
  content => "$auth_json",
  owner   => 'www-data',
  mode    => '0644',
  group   => 'www-data',
}

**/

# ## Apache & php-fpm ###

class { 'apache':
  user              => 'www-data',
  group             => 'www-data',
  mpm_module        => 'prefork',
  default_vhost     => false,
  manage_group      => false,
  keepalive         => 'On',
  keepalive_timeout => 120,
  log_formats       => {
    aws_elb => '\"%{X-Forwarded-For}i\" %l %u %t \"%r\" %>s %b \"%{Referer}i\" \"%{User-Agent}i\" %V %D',
  }
  ,
  server_tokens     => 'Major',
}

include ::php

apache::mod { 'actions': }

apache::mod { 'rewrite': }

apache::mod { 'headers': }

apache::mod { 'expires': }

class { 'apache::mod::status': allow_from => ['127.0.0.1'], }

exec { "/bin/chmod g+s /var/www/domains":
  onlyif  => "/usr/bin/test -d '/var/www/domains' && /usr/bin/test ! -g '/var/www/domains'",
  require => File["/var/www/domains"],
}

file { '/var/www/domains':
  ensure  => directory,
  owner   => 'ubuntu',
  mode    => '2775',
  group   => 'www-data',
  notify  => Class['Apache::Service'],
  require => [Package['httpd']],
}

file { '/var/lib/apache2/fastcgi':
  ensure => directory,
  owner  => 'www-data',
  group  => 'www-data',
  mode   => '0775',
}

apache::fastcgi::server { 'php_fpm':
  host       => '127.0.0.1:9000',
  # this is turned up to 5 minutes to allow time to work with xdebug without apache timing out
  timeout    => 600,
  flush      => false,
  fcgi_alias => '/php.fcgi',
  file_type  => 'application/x-httpd-php',
}

apache::vhost { 'codedeploy':
  vhost_name        => '*',
  port              => '80',
  virtual_docroot   => '/var/www/domains/%0/public',
  docroot           => '/var/www/domains/',
  serveraliases     => ['api'],
  setenv            => ['APPLICATION_ENV development'],
  directoryindex    => 'index.php index.html index.htm',
  override          => ['All'],
  options           => ['+FollowSymlinks', '+MultiViews', '-Indexes'],
  custom_fragment   => 'UseCanonicalName Off
  AllowEncodedSlashes NoDecode
  LimitRequestFieldSize 16380
  AddType application/x-httpd-php .php
  SetEnvIf Authorization "(.*)" HTTP_AUTHORIZATION=$1
  <Files "composer.json">
  order allow,deny
  deny from all
  </Files>
  Header set Access-Control-Allow-Headers "Authorization,Accept,Content-Type"
  Header set Access-Control-Allow-Origin "*"
  Header set Access-Control-Allow-Methods "GET, PUT, POST, DELETE, LINK, UNLINK"

  ## ENFORCE HTTPS FOR ALL SERVERS!!!
  RewriteEngine On
  RewriteCond %{HTTP:X-Forwarded-Proto} !https
  RewriteRule ^.*$ https://%{SERVER_NAME}%{REQUEST_URI}
  ',
  access_log_format => 'aws_elb',
  error_log_pipe    => "||/usr/bin/logger -t httpd -i -p local4.err",
  access_log_pipe   =>
    '|$/bin/grep -E --line-buffered -v \'status_20[0-9]\' | /usr/bin/logger -thttpd -i -p local4.info',
}