Feature: Configuring imaparchiver
  In order to configure imaparchiver
  A user should be able to run a configuration wizard

  Scenario: Starting the configuration wizard
    Given I have no configuration file
    When I start the configuration wizard
    Then I should see "IMAP server address"
    When I enter "imap.example.net"
    And I press return
    Then I should see "IMAP username"
    When I enter "username"
    And I press return
    Then I should see "IMAP password"
    When I enter "my password"
    And I press return
    Then the wizard should have exited normaly
