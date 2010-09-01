Feature: Configuring imaparchiver
  In order to configure imaparchiver
  A configuration file should be read

  Scenario: Parsing the configuration file
    Given a file named "/tmp/imap_archiver_config.rb" with:
    """
    ImapArchiver::Config.run do |config|
       config.imap_server = 'imap.example.net'
       config.username = 'jhelsen'
       config.password = 'secret'
       config.folders_to_archive = /test/
       config.archive_folder = "/Archive/test"
    end
    """
    When I load the configuration file "/tmp/imap_archiver_config.rb"
    Then the configuration imap_server should be "imap.example.net"
    And the configuration username should be "jhelsen"
    And the configuration password should be "secret"
    And the configuration folders_to_archive should be "/test/"
    And the configuration archive_folder should be "/Archive/test"
    
  Scenario: starting without a configuration file
    Given I have no file "/tmp/imap_archiver_config.rb"
    When I run "../../bin/imap_archiver -F /tmp/imap_archiver_config.rb"
    Then it should fail with:
    """
    Config_file not found!
    """
  
  
  Scenario: starting with an invalid configuration file
    Given a file named "/tmp/imap_archiver_config.rb" with:
    """
    ImapArchiver::Config.run do |config|
    end
    """
    When I run "../../bin/imap_archiver -F /tmp/imap_archiver_config.rb"
    Then it should fail with:
    """
    No imap server in configuration file!
    """
  
  