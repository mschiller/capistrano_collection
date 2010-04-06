#Capistrano::Configuration.instance(true).load do
  namespace :svn do
    desc "Creates a svn project on vserver; usage: cap svn:create SVNPROJECT=xxx"
    task :create, :roles => :vserver do
      svnproject = ENV['SVNPROJECT']
      sudo "svnadmin create /svn/#{svnproject}"
      run "mkdir -p /tmp/svnprojecs /tmp/svnprojecs/#{svnproject}/branches /tmp/svnprojecs/#{svnproject}/tags /tmp/svnprojecs/#{svnproject}/trunk"
      run "echo \"Project: #{svnproject}\" > /tmp/svnprojecs/#{svnproject}/trunk/README"
      sudo "svn import /tmp/svnprojecs/#{svnproject} file:///svn/#{svnproject} -m \"first import\""
      sudo "chown -R www-data:www-data /svn/#{svnproject}"
      sudo "rm -R /tmp/svnprojecs/#{svnproject}"
    end

    desc "Deletes a svn project on vserver; usage: cap svn:delete SVNPROJECT=xxx"
    task :delete, :roles => :vserver do
      svnproject = ENV['SVNPROJECT']
      sudo "rm -R /svn/#{svnproject}"
    end
  end
#end
