#Capistrano::Configuration.instance(true).load do
  set :application, ""
  
  namespace :redmine do
    desc "Restarts the cruise server"
    task :restart, :roles => :vserver do
      puts "[Deploy] Restarting redmine"
      run "cd /var/www/redmine/ && touch tmp/restart.txt"
    end
  end

  namespace :apache do
    set :apache_config_path, "/var/data/apache2_configs"

    namespace :vhost_entry do
      desc "Creates an entry for current project in apache vhost configuration"
      task :create, :roles => :web do
        #upload
        vhost_text = "
  RailsBaseURI /#{application}

  <Location \"/#{application}\">
    #PassengerRestartDir /var/projects/#{application}/current/tmp
    PassengerRestartDir /var/projects/#{application}/shared
    AuthType Basic
    AuthName \"#{application.capitalize}\"
    AuthBasicProvider file
    AuthUserFile #{password_file}
    Require valid-user
  </Location>"
        put(vhost_text, File.join(apache_config_path, application), :mode => 0644)

        # restart apache
        apache.reload
      end

      desc "Deletes the entry for current project in apache vhost configuration"
      task :delete, :roles => :web do
        run "rm -rf #{File.join(apache_config_path, application)}"
        # restart apache
        apache.reload
      end
    end

    desc "Apache reload"
    task :reload, :roles => :web do
      sudo "/etc/init.d/apache2 reload"
    end
  end

  namespace :remote do
    namespace :aws do
      desc "Backups AWS EC2 Volume to S3"
      task :backup, :roles => :aws do
        # http://docs.amazonwebservices.com/AmazonEC2/dg/2006-10-01/CLTRG-ami-bundle-vol.html
        # http://docs.amazonwebservices.com/AmazonEC2/dg/2006-10-01/CLTRG-ami-upload-bundle.html
        platform = 'i386'
        imagesize = 3000
        exclude_paths = "/tmp,/home/rails/mount/"
        #days = %w(monday tuesday wednesday thursday friday saturday sunday)
        timestamp = Time.now.strftime('%Y%d%m%H%M%S') #-#{days[Time.now.cwday]}"
        backup_path = amazon_s3_ec2_config['ec2_backup_path'] # File.join(amazon_s3_ec2_config['ec2_backup_path'], timestamp) # problems with numbers?
        bucket = File.join(amazon_s3_ec2_config['bucket_eu'], "backups", amazon_s3_ec2_config['ec2_domain'], timestamp)

        try_sudo "rm -fR #{backup_path}/*"
        sudo "#{amazon_s3_ec2_config['ec2_path']}/ec2-bundle-vol -p vol_backup -d #{backup_path} -k #{amazon_s3_ec2_config['key_file_path']} --cert #{amazon_s3_ec2_config['cert_file_path']} -u #{amazon_s3_ec2_config['user_id']} -r #{platform} --size #{imagesize} -e #{exclude_paths}"
        sudo "#{amazon_s3_ec2_config['ec2_path']}/ec2-upload-bundle -b #{bucket} -m #{backup_path}/vol_backup.manifest.xml -a #{amazon_s3_ec2_config['access_key_id']} -s #{amazon_s3_ec2_config['secret_access_key']}"
        try_sudo "rm -fR #{backup_path}/*"
      end
    end

    desc "Default setup of server, apache"
    task :setup, :roles => :web do
      sudo "apt-get -qq update"
      sudo "apt-get -qq install joe wget build-essential zlib1g-dev libssl-dev libreadline5-dev"
      sudo "apt-get -qq install apache2 apache2-prefork-dev libapr1-dev libaprutil1-dev"
      sudo "apt-get -qq install subversion exim4"
      sudo "apt-get -qq install postgresql sqlite3 libmysql++-dev libsqlite3-dev libpq-dev"
      # install mysql-server manually!
      run <<-CMD
                              for mod in #{apache_mods.join(' ')} ; do
                                      if [ ! -h /etc/apache/mods-enabled/${mod}.load ] ; then
                                              sudo /usr/sbin/a2enmod $mod ;
                                      fi
                              done
      CMD
      sudo "/etc/init.d/apache2 reload || true"
    end

    namespace :htpasswd do
      desc "Add or Change password for user "
      task :add_user do
        puts "Please input the username"
        user = $stdin.gets.chomp
        puts "Please input the password"
        password = $stdin.gets.chomp
        sudo "htpasswd -b #{password_file} #{user} #{password}"
      end

      desc "Change password for user "
      task :del_user do
        puts "Please input the username"
        user = $stdin.gets.chomp
        sudo "htpasswd -D #{password_file} #{user}"
      end
    end

    desc <<-DESC
            Reparing Server. \
            This will repare and restart Apache and Redmine
    DESC
    task :repare do
      with_role :vserver do
        puts "[Deploy] Repare vserver"
        puts "[Deploy] Restart Apache"
        # high priority!
        apache.restart

        puts "[Deploy] Restart Redmine"
        #run "cd /var/www/redmine-0.8/ && #{sudo} mongrel_rails cluster::stop && rm -f tmp/pids/mongrel* && #{sudo} mongrel_rails cluster::start"
        run "cd /var/www/redmine/ && touch tmp/restart.txt"

        puts "[Deploy] Restart Inlive"
        run "cd /var/www/inlive/ && #{sudo} mongrel_rails cluster::stop && rm -f tmp/pids/mongrel* && #{sudo} mongrel_rails cluster::start"

      end

  #        puts "[Deploy] Restart all Background- and Ferret-Server"
  #        saved_current_path = current_path
  #        projects.each do |project|
  #          puts "[Deploy] Restart Background- and Ferret-Server for '#{project}' project"
  #          # projects of one server with the same server authentication
  #          set :current_path, "/var/www/#{project}/current"
  #          find_and_execute_task("backgroundrb:restart")
  #          find_and_execute_task("ferret:stop")
  #          find_and_execute_task("ferret:start")
  #        end unless projects.nil?
  #        # auf default app zurücksetzen
  #        set :current_path, saved_current_path
    end
  end
#end
