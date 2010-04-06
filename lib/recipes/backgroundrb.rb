require 'yaml'

#Capistrano::Configuration.instance(true).load do
  set :backgroundrb_host, 'localhost'
  set :backgroundrb_env , 'production'

  namespace :backgroundrb do
    # ===============================================================
    # PROCESS MANAGEMENT
    # ===============================================================

    desc "Stops the backgroundrb worker processes"
    task :stop, :roles => :app do
      run "cd #{current_path} && #{sudo} #{ruby} script/backgroundrb stop || true; echo return_code: $?"
    end

    desc "Starts the backgroundrb worker processes"
    task :start, :roles => :app do
      run "cd #{current_path} && #{ruby} script/backgroundrb start"
    end

    desc "Restarts a running backgroundrb server."
    task :restart, :roles => :app do
      backgroundrb.stop
      sleep(5)  # sleep for 5 seconds to make sure the server has mopped up everything
      backgroundrb.start
    end

    # ===============================================================
    # PROCESS CONFIGURATION
    # ===============================================================

#    desc "Creates configuration file for the backgroundrb server"
#    task :configure, :roles => :app do
#      config = { :backgroundrb => {:ip => backgroundrb_host, :port => backgroundrb_port, :environment => backgroundrb_env} }
#      backgroundrb_yml = config.to_yaml
#
#      run "if [ ! -d #{shared_path}/config ]; then mkdir #{shared_path}/config; fi"
#      put(backgroundrb_yml, "#{shared_path}/config/backgroundrb.yml", :mode => 0644)
#    end
  end
#end
