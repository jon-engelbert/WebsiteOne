Feature:
  In order to know which events I can join
  As a member
  I would like a see a list of planned events

  Background:
    Given following alpha_event exist:
      | title    | start_planned  | tags                       | agenda                 | comments                      |
      | event 1 | 2025/08/14 10:00 UTC | websiteone, pp, ruby       | Refactor index spec    | Bring you own laptop          |
      | event 2 | 2010/09/14 16:45 UTC| autograder, client, deploy | finish the rag feature | Show the client the latest UI |

  Scenario: Displaying a list of planned events
    When I am on the "alpha_events" page
    Then I should see:
      | event 1              |
      | 25-08-14 10:00       |
      | websiteone, pp, ruby |
      | Refactor index spec  |
      | Bring you own laptop |
    And I should see:
      | event 2                       |
      | 10-09-14 16:45                |
      | autograder, client, deploy    |
      | finish the rag feature        |
      | Show the client the latest UI |

  Scenario: Creating an event
    Given I am on the "alpha_events" page
    And I am logged in
    When I click "New Event"
    When I fill in an alpha event:
      | name          | value                |
      | alpha_event_title         | event 3              |
      | alpha_event_start_planned | 2015/12/15 17:23       |
      | alpha_event_tags          | codelia, pp, angular |
      | alpha_event_agenda        | finish UI            |
      | alpha_event_comments      | edit LoFis           |
    And I click the "Save" button
    Then I should be on the "alpha_events" page
    Then I should see "Event has been created"
    And I should see:
      | event 3              |
      | 2015-12-15 17:23       |
      | codelia, pp, angular |
      | finish UI            |
      | edit LoFis           |

  Scenario: Show an event
    Given I am on the "alpha_events" page
    And I am logged in
    When I click the Show link for the first alpha event
    Then I should be on the "Show" page for alpha event "event 1"
    And I should see:
      | event one            |
      | 2015-12-15 17:23       |
      | websiteone, pp, ruby |
      | Refactor index spec            |
      | Bring you own laptop           |

  Scenario: Edit/Update an event
    Given I am on the "alpha_events" page
    And I am logged in
    When I click the Edit link for the first alpha event
    Then I should be on the "Edit" page for alpha event "event 1"
    When I fill in an alpha event:
      | name          | value                |
      | alpha_event_title         | event one              |
      | alpha_event_start_planned | 2025/08/14 10:00       |
      | alpha_event_tags          | codelia, pp, angular |
      | alpha_event_agenda        | finish UI            |
      | alpha_event_comments      | edit LoFis           |
    And I click the "Save" button
    Then I should be on the "alpha_event" page
    Then I should see "Event has been updated"
    And I should see:
      | event one            |
      | 2025-08-14 10:00       |
      | codelia, pp, angular |
      | finish UI            |
      | edit LoFis           |

  Scenario: Delete an existing event
    Given I am on the "alpha_events" page
    And I am logged in
    When I click the Delete link for the alpha event 'event 1'

#    Given I am on the "show" page for alpha_event "event 1"
#    And I am logged in
#    When I click the delete button for the event "event 1"
    Then I should see "Are you sure?"

    When I accept the warning popup
    Then I should see "Event has been deleted"
    And I should be on the "alpha_event" page
    And I should not see:
      | event 1              |
      | 25/08/14 10:00       |
      | websiteone, pp, ruby |
      | Refactor index spec  |
      | Bring you own laptop |
