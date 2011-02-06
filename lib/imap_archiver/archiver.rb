require "logger"
require "config"
module ImapArchiver
  class Archiver
    include ::ImapArchiver::Config
    attr_accessor :connection
    def initialize(config_file,debug=false)
      @logger = Logger.new(STDOUT)
      @logger.level = Logger::WARN
      if debug
        @logger.level = Logger::DEBUG
        @logger.debug "Debugging enabled."
      end
      @logger.debug "Loading config"
      self.load_config(config_file)
      @logger.debug "config loaded"
      config_valid?
      @logger.debug "config valid"
    end
    
    def connect
      self.reconnect
      @msg_count = 0
    end
    
    def reconnect
      @logger.debug "reconnect"
      self.connection = Net::IMAP.new(imap_server) rescue nil
      @logger.debug "connected"
      capability = self.connection.capability rescue nil
      @logger.debug "capability: #{capability.inspect}"
      if capability.detect {|c| c =~ /AUTH=(CRAM|DIGEST)-MD5/}
        @logger.debug "loging in with #{auth_mech}"
        self.connection.authenticate(auth_mech,username,password)
      else
        @logger.debug "plain login"
        self.connection.login(username,password) rescue nil
      end
    end
    
    def folder_list
      @logger.debug "folder_list"
      connect if connection.nil?
      if folders_to_archive.is_a? Array
        folders = folders_to_archive.map {|f| connection.list('',f)}
        return folders.delete_if(&:nil?).map(&:first)
      end
      if folders_to_archive.is_a? Regexp
        folders = connection.list("","*")
        return folders.delete_if {|f| (f.name =~ folders_to_archive).nil? }
      end
      connection.list(base_folder,"*")
    end
    
    def start 
      @logger.debug "start"
      folder_list.each do |folder|        
        @logger.debug "starting folder #{folder}"
        since_date = Date.today.months_ago(3).beginning_of_month 
        before_date= Date.today.months_ago(2).beginning_of_month 
        archive_folder_between_dates(folder.name,since_date,before_date) #if folder.name =~ /^Public Folders\/Team\//
      end
    end
    
    def archive_folder_between_dates(folder, since_date, before_date)
      @logger.debug "archive_folder_between_dates #{folder}, #{since_date}, #{before_date}"
      tmp_folder = Pathname.new(folder).relative_path_from(Pathname.new(base_folder)).to_s
      current_archive_folder = "#{archive_folder}/#{tmp_folder}/#{since_date.strftime("%b %Y")}"
      @logger.debug "archiving to #{archive_folder}"
      conditions = ["SINCE", since_date.strftime("%d-%b-%Y"), "BEFORE", before_date.strftime("%d-%b-%Y"), "SEEN", "NOT", "FLAGGED"]
      @logger.debug conditions.join(" ")
      retry_count = 0
      begin
        connection.select(folder)
        # puts "will search 1"
        msgs_to_archive = connection.uid_search(conditions)
        @logger.debug "#{msgs_to_archive.size} msgs to archive"
        if msgs_to_archive.size > 0
          @logger.debug "will archive #{msgs_to_archive.size} messages"
          if connection.list("",current_archive_folder).nil?
            @logger.debug "creating archive folder #{current_archive_folder}"
            connection.create(current_archive_folder)
            if connection.capability.include?("ACL")
              self.archive_folder_acl.each do |key,value|
                connection.setacl(current_archive_folder,key,value)
              end
            end
          end
          while !msgs_to_archive.empty? && (msgs = msgs_to_archive.slice!(0,100))
            connection.uid_copy(msgs, current_archive_folder)
            connection.uid_store(msgs, "+FLAGS",[:Deleted])
            @msg_count += msgs.size
          end
          connection.expunge
        end
        if connection.search(["BEFORE", since_date.strftime("%d-%b-%Y"), "SEEN", "NOT", "FLAGGED"]).size > 0
          archive_folder_between_dates(folder,since_date.prev_month, since_date)
        end
      rescue IOError => e
        retry_count += 1
        @logger.debug e.backtrace
        @logger.debug "retrying"
        if retry_count < 3
          reconnect
          retry
        else
          puts "Error archiving #{folder} to #{archive_folder}: #{e}"
          puts e.backtrace
        end
        rescue Net::IMAP::NoResponseError => e
          puts "#{e}: #{folder}: #{e.backtrace.join("\n")}"
      # rescue Exception => e
      #   retry_count += 1
      #   if retry_count < 3
      #     puts "retrying #{e}"
      #     retry
      #   else
      #     puts "Error archiving #{folder} to #{archive_folder}: #{e}"
      #     puts e.backtrace
      #   end
      end
    end
    
    def self.run(config_file,debug=false)
      self.new(config_file,debug).start
    end    
  end
end
