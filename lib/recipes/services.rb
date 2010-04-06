#Capistrano::Configuration.instance(true).load do
  namespace :deploy do
    namespace :worker do
      desc "Start workling client"
      task :start, :roles => :app do
        run "cd #{current_path} && RAILS_ENV=production ./script/workling_client start"
      end

      desc "Restart workling client"
      task :restart, :roles => :app do
        run "cd #{current_path} && RAILS_ENV=production ./script/workling_client stop"
        run "cd #{current_path} && RAILS_ENV=production ./script/workling_client start"
      end

      desc "Stop workling client"
      task :stop, :roles => :app do
        run "cd #{current_path} && RAILS_ENV=production ./script/workling_client stop"
      end
    end

    namespace :starling do
      desc "Start starling service"
      task :start, :roles => :app do
        # the first entry of listens_on list is winning
        port = Array(workling_config['listens_on']).first.split(':').last
        run "cd #{current_path} && PORT=#{port} #{rake_path} starling:start"
      end

      desc "Stop starling service"
      task :stop, :roles => :app do
        run "cd #{current_path} && #{sudo} #{rake_path} starling:stop"
      end

      desc "Restart starling service"
      task :restart, :roles => :app do
        deploy.starling.stop
        sleep 2
        deploy.starling.start
      end

      desc "Setup starling server"
      task :setup, :roles => :app do
        run "cd #{current_path} && #{sudo} #{rake_path} starling:setup"
      end
    end

    namespace :memcached do
      desc "Start memcached server"
      task :start, :roles => :app do
        run "cd #{current_path} && #{sudo} #{rake_path} memcached:start"
      end
      desc "Restart memcached server"
      task :restart, :roles => :app do
        run "cd #{current_path} && #{sudo} #{rake_path} memcached:restart"
      end

      desc "Stop memcached server"
      task :stop, :roles => :app do
        run "cd #{current_path} && #{sudo} #{rake_path} memcached:stop"
      end
    end
  end
#end

