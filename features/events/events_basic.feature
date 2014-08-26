Feature:
  In order to know which events I can join
  As a member
  I would like a see a list of planned events

  Background:
    Given following events exist:
      | name   | start_planned  | tags                       | agenda                 | comments                      |
      | event 1 | 25/08/14 10:00 | websiteone, pp, ruby       | Refactor index spec    | Bring you own laptop          |
      | event 2 | 10/09/14 16:45 | autograder, client, deploy | finish the rag feature | Show the client the latest UI |

  Scenario: Displaying a list of planned events
    When I am on Events index page
    Then I should see:
    #all kinds of UI: lables, tables
    Then I should see:
      | event 1              |
      | 25/08/14 10:00       |
      | websiteone, pp, ruby |
      | Refactor index spec  |
      | Bring you own laptop |
    Then I should see:
      | event 2                       |
      | 10/09/14 16:45                |
      | autograder, client, deploy    |
      | finish the rag feature        |
      | Show the client the latest UI |

  Scenario: Creating an event
    Given I am on the new page for Event
    When I fill in an event with details:
      | name          | value          |
      | title         | event 2        |
      | start_planned | 04/12/15 17:23 |
      | tags          | codelia, pp, angular |
      | agenda        | finish UI      |
      | comments      | edit LoFis     |
    And I click the "Save" button
    Then I should see "Event has been created"
    Then I should be on the Events "Index" page
    And I should see:
      | event 2              |
      | 04/12/15 17:23       |
      | codelia, pp, angular |
      | finish UI            |
      | edit LoFis           |

  Scenario: Delete an existing event
    Given I am on the show page for event "event 1"
    When I click the "Delete" button
    Then I should see "Are you sure?"

    When I accept the warning popup
    Then I should see "Event has been deleted"
    And I should be on the Events "Index" page
    Then I should not see:
      | event 1              |
      | 25/08/14 10:00       |
      | websiteone, pp, ruby |
      | Refactor index spec  |
      | Bring you own laptop |
