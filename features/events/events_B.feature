Feature:
  In order to know which events are pending and active, and create hangouts and join them
  As a member
  I would like a see a list of planned events and live with functional links to create and join

  Background:
    Given following planned events exist:
      | name    | start_planned  | tags                 | agenda              | comments             | assets | creator |
      | event 1 | 25/08/14 10:00 | websiteone, pp, ruby | Refactor index spec | Bring your own laptop | asset1 | sam     |
    And following actual events exist:
      | name    | start_planned  | tags                       | agenda                 | comments                      | assets | host   | start_actual            | duration-actual | hangout_url  | youtube_url  |
      | event 2 | 10/09/14 16:45 | autograder, client, deploy | finish the rag feature | Show the client the latest UI | asset2 | Thomas | 2014-08-26 12:00:00 UTC | 90              | http://a.com | http://a.com |

  Scenario: Displaying a list of planned events
    When I am on Events index page
    Then I should see:
    #all kinds of UI: lables, tables
    Then I should see:
      | event 1              |
      | 25/08/14 10:00       |
      | websiteone, pp, ruby |
      | Refactor index spec  |
      | Bring your own laptop |
    Then I should see:
      | event 2                       |
      | 10/09/14 16:45                |
      | autograder, client, deploy    |
      | finish the rag feature        |
      | Show the client the latest UI |

  Scenario: Creating an event
    Given I am on the new page for Event
    When I fill in an event with details:
      | name          | value                |
      | title         | event 2              |
      | start_planned | 04/12/15 17:23       |
      | tags          | codelia, pp, angular |
      | agenda        | finish UI            |
      | comments      | edit LoFis           |
    And I click the "Save" button
    Then I should see "Event has been created"
    Then I should be on the Events "Index" page
    And I should see:
      | event 2              |
      | 04/12/15 17:23       |
      | codelia, pp, angular |
      | finish UI            |
      | edit LoFis           |

  Scenario: Starting hangout for an event
    Given I am on Events index page
    When I fill in an event with details:
      | name          | value                |
      | title         | event 2              |
      | start_planned | 04/12/15 17:23       |
      | tags          | codelia, pp, angular |    When I fill in an event with details:

      | agenda        | finish UI            |
      | comments      | edit LoFis           |
    And I click the "Save" button
    Then I should see "Event has been created"
    Then I should be on the Events "Index" page
    And I should see:
      | event 2              |
      | 04/12/15 17:23       |
      | codelia, pp, angular |
      | finish UI            |
      | edit LoFis           |

