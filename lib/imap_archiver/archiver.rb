require "config"
module ImapArchiver
  class Archiver
    include ::ImapArchiver::Config
    attr_accessor :connection
    def initialize(config_file)
      self.load_config(config_file)
      config_valid?
    end
    
    def connect
      self.reconnect
      @msg_count = 0
    end
    
    def reconnect
      self.connection = Net::IMAP.new(imap_server)
      self.connection.authenticate(auth_mech,username,password)
    end
    
    def folder_list
      connect if connection.nil?
      if folders_to_archive.is_a? Array
        folders = folders_to_archive.map {|f| connection.list('',f)}
        return folders.delete_if {|f| f.nil?}
      end
      if folders_to_archive.is_a? Regexp
        folders = connection.list("","*")
        return folders.delete_if {|f| (f.name =~ folders_to_archive).nil? }
      end
      connection.list(base_folder,"*")
    end
    
    def start 
      folder_list.each do |folder|        
        since_date = Date.today.months_ago(3).beginning_of_month 
        before_date= Date.today.months_ago(3).end_of_month 
        archive_folder_between_dates(folder.name,since_date,before_date) #if folder.name =~ /^Public Folders\/Team\//
      end
    end
    
    def archive_folder_between_dates(folder, since_date, before_date)
      tmp_folder = Pathname.new(folder).relative_path_from(Pathname.new('Public Folders')).to_s
      archive_folder = "Public Folders/Archief/#{tmp_folder}/#{since_date.strftime("%b %Y")}"
      # puts archive_folder
      conditions = ["SINCE", since_date.strftime("%d-%b-%Y"), "BEFORE", before_date.strftime("%d-%b-%Y"), "SEEN", "NOT", "FLAGGED"]
      retry_count = 0
      begin
        connection.select(folder)
        # puts "will search 1"
        msgs_to_archive = connection.search(conditions)
        if msgs_to_archive.size > 0
          # puts "will archive #{msgs_to_archive.size} messages"
          if connection.list("",archive_folder).nil?
            connection.create(archive_folder)
          end
          connection.copy(msgs_to_archive, archive_folder)
          connection.store(msgs_to_archive, "+FLAGS",[:Deleted])
          @msg_count += msgs_to_archive.size
          connection.expunge
        end
        if connection.search(["BEFORE", since_date.strftime("%d-%b-%Y"), "SEEN", "NOT", "FLAGGED"]).size > 0
          archive_folder_between_dates(folder,since_date - 1.month, since_date)
        end
      rescue IOError => e
        retry_count += 1
        # puts "retrying"
        if retry_count < 3
          reconnect
          retry
        else
          puts "Error archiving #{folder} to #{archive_folder}: #{e}"
          puts e.backtrace
        end
      rescue Exception => e
        retry_count += 1
        if retry_count < 3
          puts "retrying #{e}"
          retry
        else
          puts "Error archiving #{folder} to #{archive_folder}: #{e}"
          puts e.backtrace
        end
      end
    end
    
    def self.run(config_file)
      self.new(config_file).start
    end    
  end
end