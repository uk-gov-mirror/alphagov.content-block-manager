Feature: View a content object
  Background:
    Given I am logged in
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
    And the schema has a subschema "rates":
    """
    {
      "type":"object",
      "required": ["title", "amount"],
      "properties": {
        "title": {
          "type": "string"
        },
        "amount": {
          "type": "string",
          "pattern": "£[0-9]+\\.[0-9]+"
        },
        "frequency": {
          "type": "string",
          "enum": [
            "a week",
            "a month"
          ]
        }
      }
    }
    """
    And a pension content block has been created
    And that pension has a rate with the following fields:
      | title   | amount  | frequency |
      | My rate | £123.45 | a week    |
    And a schema "contact" exists:
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
    And a contact content block has been created

  Scenario: GDS Editor views a content object
    When I visit the Content Block Manager home page
    Then I should see the details for all documents
    When I click to view the document
    Then I should be taken back to the document page
    And I should see the details for the contact content block
    And I should see the status of the latest edition of the block
    And I should see the contact created event on the timeline

  Scenario: GDS Editor views a content object using the content ID
    When I visit a block's content ID endpoint
    And I should see the details for the contact content block

  Scenario: GDS Editor views dependent Content
    Given dependent content exists for a content block
    When I visit the Content Block Manager home page
    And I click to view the document
    Then I should see the dependent content listed
    And I should see the rollup data for the dependent content

  @javascript
  Scenario: GDS Editor can copy embed code for a specific field
    When I visit the Content Block Manager home page
    And I click to view the document with title "My pension"
    Then I should not see the pension rate embed code displayed
    
    When I click to copy the embed code for the pension rate
    Then the pension rate embed code should be copied to my clipboard
    And I should see the pension rate embed code flash up for an interval

  Scenario: GDS Editor without javascript can see embed code
    When I visit the Content Block Manager home page
    And I click to view the document with title "My pension"
    Then the pension rate embed code should be visible

  @javascript
  Scenario: Editor can copy embed code for default contact block
    When I visit the Content Block Manager home page
    And I click to view the document with title "My contact"
    Then I should not see the contact default block embed code displayed
    And there should be no accessibility errors

    When I click to copy the embed code for the contact's default block
    Then the contact default block embed code should be copied to my clipboard
    And I should see the contact default block embed code flash up for an interval
    And there should be no accessibility errors

  Scenario: Editor without javascript can see embed code for default contact block
    When I visit the Content Block Manager home page
    And I click to view the document with title "My contact"
    Then the contact default block embed code should be visible

