require 'optparse'

module ImapArchiver
  class CLI
    def self.execute(stdout,stdin, arguments=[])

      # NOTE: the option -p/--path= is given as an example, and should be replaced in your application.
      options = {
        :config_file => "~/.imap_archiver.rb",
        :debug => false
      }
      mandatory_options = %w(  )

      parser = OptionParser.new do |opts|
        opts.banner = <<-BANNER.gsub(/^          /,'')
          Usage: #{File.basename($0)} [options]

          Options are:
        BANNER
        opts.separator ""
        opts.on("-h", "--help",
                "Show this help message.") { stdout.puts opts; exit }
        opts.on("-d", "--debug", "Enable debugging.") { options[:debug] = true}
        opts.on("-F PATH", "", String, "Configuration file", "Default: ~/.imap_archiver.yml"){|arg| options[:config_file] = arg}
        opts.parse!(arguments)

        if mandatory_options && mandatory_options.find { |option| options[option.to_sym].nil? }
          stdout.puts opts; exit
        end
      end
      
      # Config.load_config(options[:config_file])
      Archiver.run(options[:config_file],options[:debug])
      
      return 0
    end
  end
end
