#Capistrano::Configuration.instance(true).load do
  namespace :rubygems do
    desc "Performs a rubygems upgrade, updates all gems and cleans up old ones"
    task :full_update, :roles => :app do
      rubygems.upgrade
      rubygems.update
      rubygems.cleanup
    end

    desc "Upgrades the rubygem package installation"
    task :upgrade, :roles => :app do
      if fetch(:ruby_paths, nil)
      Array(ruby_paths).each { |path| sudo "#{path}/gem update --system" }
      else
        sudo "#{base_ruby_path}/bin/gem update --system" if ENV['WITH_SUDO']
        run "#{base_ruby_path}/bin/gem update --system" unless ENV['WITH_SUDO']
      end
    end

    desc "Updates all installed gems"
    task :update, :roles => :app do
      if fetch(:ruby_paths, nil)
      Array(ruby_paths).each { |path| sudo "#{path}/gem update" }
      else
        sudo "#{base_ruby_path}/bin/gem update" if ENV['WITH_SUDO']
        run "#{base_ruby_path}/bin/gem update" unless ENV['WITH_SUDO'] 
      end
    end

    desc "Removes old gems which are now outdated"
    task :cleanup, :roles => :app do
      if fetch(:ruby_paths, nil)
        Array(ruby_paths).each { |path| sudo "#{path}/gem cleanup" }
      else
        sudo "#{base_ruby_path}/bin/gem cleanup" if ENV['WITH_SUDO']
        run "#{base_ruby_path}/bin/gem cleanup" unless ENV['WITH_SUDO']
      end
    end

    desc "Install a gem on your servers servers"
    task :install, :roles => :app do
      puts "Enter the name of the gem you'd like to install:"
      gem_name = $stdin.gets.chomp
      logger.info "trying to install '#{gem_name}'"
      if fetch(:ruby_paths, nil)
        Array(ruby_paths).each {|path| sudo "#{path}/gem install #{gem_name} --no-ri --no-rdoc" } if ENV['WITH_SUDO']
        Array(ruby_paths).each {|path| "#{path}/gem install #{gem_name} --no-ri --no-rdoc" } unless ENV['WITH_SUDO']
      else
        sudo "#{base_ruby_path}/bin/gem install #{gem_name} --no-ri --no-rdoc" if ENV['WITH_SUDO']
        run "#{base_ruby_path}/bin/gem install #{gem_name} --no-ri --no-rdoc" unless ENV['WITH_SUDO']
      end
    end

    desc "Uninstall a gem from the release servers"
    task :uninstall, :roles => :app do
      puts "Enter the name of the gem you'd like to remove:"
      gem_name = $stdin.gets.chomp
      logger.info "trying to remove '#{gem_name}'"
      if fetch(:ruby_paths, nil)
        Array(ruby_paths).each { |path| sudo "#{path}/gem uninstall #{gem_name} -x" }
      else
        sudo "#{base_ruby_path}/bin/gem uninstall #{gem_name} -x"
      end
    end 
    
    desc "Lists all installed gems"
    task :list, :roles => :app do 
      if fetch(:ruby_paths, nil)
        Array(ruby_paths).each { |path| run "#{path}/bin/gem list" }
      else
        run "#{base_ruby_path}/bin/gem list"
      end
    end

    desc "Setup: Install all important gems"
    task :setup, :roles => :app do
      puts "[RubyGems Setup] start installation"
      Array(fetch(:default_gems, []).each {|g| sudo "#{base_ruby_path}/bin/gem install #{g}"})
    end

    namespace :rake do
      namespace :install do
        desc "Installiert alle nicht vorhandenen Gems, die einem beliebigen Environment zugeordnet wurde; cap rubygems:install_all [WITH_SUDO]n"
        task :all, :roles => :app do
          # Es muss der Pfad zum aktuellen Ruby angegeben werden, da sonst zwar das richtige RAKE aufgerufen wird, aber möglicherweise das falsche Ruby!
          # Install the gems in the home .gem of rails
          env = fetch(:rails_env, "production")
          if fetch(:ruby_paths, nil)
            unless ENV['WITH_SUDO']
              Array(ruby_paths).each {|path| run "cd #{current_path} && #{path}/rake RAILS_ENV=#{env} gems:install:all"}
            else
              Array(ruby_paths).each {|path| run "cd #{current_path} && #{sudo} GEM_PATH=#{base_ruby_path}/lib/ruby/gems/1.8 PATH=#{path}:$PATH #{path}/rake RAILS_ENV=#{env} gems:install:all"}
            end
          else
            unless ENV['WITH_SUDO']
              run "cd #{current_path} && #{rake_path} RAILS_ENV=#{env} gems:install:all"
            else
              run "cd #{current_path} && #{sudo} GEM_PATH=#{base_ruby_path}/lib/ruby/gems/1.8 PATH=#{base_ruby_path}/bin:$PATH #{rake_path} RAILS_ENV=#{env} gems:install:all"
            end
          end
        end

        desc "Installiert alle nicht vorhandenen Gems des zuvor definierten Environments (Standard: production); cap rubygems:install [WITH_SUDO]"
        task :default, :roles => :app do
          # Install the gems in the home .gem of rails
          env = fetch(:rails_env, "production")
          if fetch(:ruby_paths, nil)
            unless ENV['WITH_SUDO']
              Array(ruby_paths).each {|path| run "cd #{current_path} && #{path}/rake RAILS_ENV=#{env} gems:install"}
            else
              Array(ruby_paths).each {|path| run "cd #{current_path} && #{sudo} GEM_PATH=#{base_ruby_path}/lib/ruby/gems/1.8 PATH=#{path}:$PATH #{path}/rake RAILS_ENV=#{env} gems:install"}
            end
          else
            unless ENV['WITH_SUDO']
              run "cd #{current_path} && #{rake_path} RAILS_ENV=#{env} gems:install"
            else
                run "cd #{current_path} && #{sudo} GEM_PATH=#{base_ruby_path}/lib/ruby/gems/1.8 PATH=#{base_ruby_path}/bin:$PATH #{rake_path} RAILS_ENV=#{env} gems:install"
            end
          end
        end
      end
    end
  end
#end
