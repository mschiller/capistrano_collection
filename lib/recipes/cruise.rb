# Projektspezifische Cap Recipes
#Capistrano::Configuration.instance(true).load do
  namespace :cruise do

    set :cruise_init_path, "/etc/init.d/cruise"
    set :cruise_path, "/var/projects/cruise"
    set :cruise_project_path, "/var/data/cruise/projects"
    set :cruise_data_path, "/var/data/cruise"
    set :template_path, "/var/data/templates"

    desc "Stops the cruise server"
    task :stop, :roles => :testserver do
      puts "[Deploy] Stopping the cruise server"
      sudo "#{cruise_init_path} stop"
    end

    desc "Starts the cruise server"
    task :start, :roles => :testserver do
      puts "[Deploy] Starting the cruise server"
      sudo "#{cruise_init_path} start"
    end

    desc "Restarts the cruise server"
    task :restart, :roles => :testserver do
      puts "[Deploy] Restarting the cruise server"
      sudo "#{cruise_init_path} restart"
    end

    desc "Add a project to cruise control. Example: cap cruise:add_project NAME=xxx SOURCE=git REPOS=repository_url "
    task :add_project, :roles => :testserver do
      project = ENV['NAME'] || fetch(:application, nil)
      repos = ENV['REPOS'] || fetch(:repository, nil)
      source = ENV['SOURCE'] || fetch(:source, 'svn')
      branch = ENV['BRANCH'] || fetch(:source, 'master')
      username = ENV['USERNAME'] || Capistrano::CLI.ui.ask("Please input optional username: ")
      password = Capistrano::CLI.password_prompt("Please input optional user password: ")

      unless project && repos
        raise ArgumentError, "***** You must specify the NAME and (SVN) REPOS parameters to add a project.
             Example: cap cruise:add_project NAME=test REPOS=https://xxx *****"
      end

      puts "[Deploy] Stopping the cruise server"
      sudo "#{cruise_init_path} stop"
      puts "[Deploy] ADD project"
      branch_entry = ("--branch #{branch}" if branch) || ""
      username_entry = ("--username #{username}" if username) || ""
      password_entry = ("--password #{password}" if password) || ""
      repos_user = ("#{username}@" if source == "git") || ""
      run "export CRUISE_DATA_ROOT=#{cruise_data_path}; #{cruise_path}/cruise add #{project} --source-control #{source} --repository #{repos_user}#{repos} #{branch_entry} #{username_entry} #{password_entry}"
      puts "[Deploy] kopiere projektconfig-vorlage"
      run "cp #{template_path}/cruise_config_template.rb #{cruise_project_path}/#{project}/cruise_config.rb"
      puts "[Deploy] set mod 774 for new project"
      sudo "chmod -R 774 #{cruise_project_path}/"
      puts "[Deploy] Starting the cruise server"
      sudo "#{cruise_init_path} start"

      # create config
      un = cruise_mysql_username || Capistrano::CLI.ui.ask("Please input database username: ")
      pw = cruise_mysql_password || Capistrano::CLI.password_prompt("Please input database user password: ")
      database_config = { "test" => {'adapter' => "mysql", 'encoding' => "utf8",
                                           'host' => "localhost", 'database' => "cruise_#{project}_test",
                                           'username' => un, 'password' => pw},
                          "cucumber" => {'adapter' => "mysql", 'encoding' => "utf8",
                                           'host' => "localhost", 'database' => "cruise_#{project}_cucumber",
                                           'username' => un, 'password' => pw}
      }
      # upload database configuration
      work_config_path = "#{cruise_project_path}/#{project}/work/config"
      put(database_config.to_yaml, "#{work_config_path}/database.yml", :mode => 0644)
      # copy example configurations to cruise project
      put(YAML.load_file("config/memcached.yml.example").to_yaml, "#{work_config_path}/memcached.yml", :mode => 0644) rescue nil
      put(YAML.load_file("config/workling.yml.example").to_yaml, "#{work_config_path}/workling.yml", :mode => 0644) rescue nil
      put(YAML.load_file("config/config.local.yml.example").to_yaml, "#{work_config_path}/config.local.yml", :mode => 0644) rescue nil
      put(YAML.load_file("config/amazon_s3.yml.example").to_yaml, "#{work_config_path}/amazon_s3.yml", :mode => 0644) rescue nil
      put(YAML.load_file("config/backgroundrb.yml.example").to_yaml, "#{work_config_path}/backgroundrb.yml", :mode => 0644) rescue nil
      put(YAML.load_file("config/ferret_server.yml.example").to_yaml, "#{work_config_path}/ferret_server.yml", :mode => 0644) rescue nil

      puts "[Deploy] Creates databases"
      ENV['N'] = "cruise_#{project}_test"
      db.mysql.create
      ENV['N'] = "cruise_#{project}_cucumber"
      db.mysql.create
    end

    desc "Start a builder for a project.
          Usage: rake cruise:start_builder PROJECT=testapp
          Usage without project: rake cruise:start_builder NAME=testapp"
    task :start_builder, :roles => :testserver do
      if ENV['NAME']
        run "#{cruise_path}/cruise build #{ENV['NAME']}" # &"
      else
        run "#{cruise_path}/cruise build #{application}" # &"
      end
    end

    desc "Start a builder for a project.
          Usage: rake cruise:remove_project PROJECT=testapp
          Usage without project: rake cruise:remove_project NAME=testapp"
    task :remove_project, :roles => :testserver do
      project = ENV['NAME'] || application
      raise ArgumentError, "***** You must specify the NAME of the project to build. Example: cap cruise:remove_project NAME=test *****" unless project
      puts "[Deploy] Stopping the cruise server"
      sudo "#{cruise_init_path} stop"
      puts "[Deploy] Stopping the cruise server"
      sudo "rm -r #{cruise_project_path}/#{project}"
      puts "[Deploy] Starting the cruise server"
      sudo "#{cruise_init_path} start"
    end
  end
#end
