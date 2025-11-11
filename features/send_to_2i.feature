Feature: Editor sends edition to 2i
  - So that I can get feedback from a 2nd pair of eyes before publishing
  - As an editor who has prepared a new (or first) edition of a block
  - I want my edition to go into an `awaiting_2i` state after `draft` and en route
    to becoming ultimately `published`

  Background:
    Given I am logged in
    And I have the PRE_RELEASE_FEATURES authorisation
    And the organisation "Ministry of Example" exists
    And a schema "pension" exists:
    """
    {
       "type":"object",
       "required":[
          "description"
       ],
       "additionalProperties":false,
       "properties":{
          "description": {
            "type": "string"
          }
       }
    }
    """
    And a pension content block has been drafted

  Scenario: Send to 2i from block show page
    When I visit the Content Block Manager home page
    And I click to view the document
    Then I see that the edition is in draft state
    And I see a principal call to action of 'Send to 2i'
    And I see a secondary call to action of 'Edit pension'
    # And I have a link to published edition
    # And I have a link to delete the edition

    When I opt to send the edition to 2i
    Then I see that the edition is in awaiting_2i state

  Scenario: Send to 2i from review step in workflow
    When I visit the Content Block Manager home page
    And I click to view the document
    Then I see that the edition is in draft state

    When I follow the workflow steps through to the final review step
    Then I see a principal call to action of 'Send to 2i'

    When I opt to send the edition to 2i
    Then I see that the edition is in awaiting_2i state