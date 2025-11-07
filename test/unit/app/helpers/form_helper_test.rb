require "test_helper"

class FormHelperTest < ActionView::TestCase
  extend Minitest::Spec::DSL

  describe "#ga4_data_attributes" do
    let(:document) { stub(block_type: "email_address", is_new_block?: false) }
    let(:edition) { stub(document: document) }
    let(:section) { "details" }

    let(:result) { ga4_data_attributes(edition: edition, section: section) }

    it "returns correctly structured data attributes with edition and section" do
      assert_equal "ga4-form-tracker", result[:data][:module]
      assert_equal "Content Block", result[:data][:ga4_form][:type]
      assert_equal "email_address", result[:data][:ga4_form][:tool_name]
      assert_equal "update", result[:data][:ga4_form][:event_name]
      assert_equal "details", result[:data][:ga4_form][:section]
    end

    describe "when an edition's document is nil" do
      let(:document) { nil }

      it "returns event_name as 'create'" do
        assert_equal "create", result[:data][:ga4_form][:event_name]
      end

      it "returns nil for tool_name" do
        assert_nil result[:data][:ga4_form][:tool_name]
      end

      describe "when a block_type is given" do
        let(:block_type) { "contact_information" }
        let(:result) { ga4_data_attributes(edition: edition, section: section, block_type: block_type) }

        it "the block type as the tool_name" do
          assert_equal "contact_information", result[:data][:ga4_form][:tool_name]
        end
      end
    end

    describe "when an edition is nil" do
      let(:edition) { nil }

      it "returns event_name as 'create'" do
        assert_equal "create", result[:data][:ga4_form][:event_name]
      end

      it "returns nil for tool_name" do
        assert_nil result[:data][:ga4_form][:tool_name]
      end
    end

    describe "when an edition's document is a new block" do
      let(:document) { stub(block_type: "email_address", is_new_block?: true) }

      it "returns event_name as 'create'" do
        result = ga4_data_attributes(edition: edition, section: section)

        assert_equal "create", result[:data][:ga4_form][:event_name]
      end
    end
  end

  describe "#event_name_for_edition" do
    let(:edition) { stub(document: document) }

    describe "when an edition's document is nil" do
      let(:document) { nil }

      it "returns 'create'" do
        edition = stub(document: nil)

        result = event_name_for_edition(edition)

        assert_equal "create", result
      end
    end

    describe "when an edition is nil" do
      let(:edition) { nil }

      it "returns 'create'" do
        result = event_name_for_edition(edition)

        assert_equal "create", result
      end
    end

    describe "when an edition's document is a new block" do
      let(:document) { stub(is_new_block?: true) }

      it "returns 'create'" do
        edition = stub(document: nil)

        result = event_name_for_edition(edition)

        assert_equal "create", result
      end
    end

    describe "when an edition's document is not a new block" do
      let(:document) { stub(is_new_block?: false) }

      it "returns 'create'" do
        edition = stub(document: nil)

        result = event_name_for_edition(edition)

        assert_equal "create", result
      end
    end
  end

  describe "#value_for_field" do
    let(:field1) { stub(name: "foo", default_value: nil) }
    let(:field2) { stub(name: "bar", default_value: "baz") }
    let(:details) { { "foo" => "bar" } }

    describe "when populate_with_defaults is true" do
      let(:populate_with_defaults) { true }

      it "returns the value for the field if present" do
        assert_equal "bar", value_for_field(details: details, field: field1, populate_with_defaults:)
      end

      it "returns the default value for the field if not present" do
        assert_equal "baz", value_for_field(details: details, field: field2, populate_with_defaults:)
      end

      describe "when details is nil" do
        let(:details) { nil }

        it "returns nil if there is no default value" do
          assert_nil value_for_field(details: details, field: field1, populate_with_defaults:)
        end

        it "returns the default value for the field" do
          assert_equal "baz", value_for_field(details: details, field: field2, populate_with_defaults:)
        end
      end
    end

    describe "when populate_with_defaults is false" do
      let(:populate_with_defaults) { false }

      it "returns the value for the field if present" do
        assert_equal "bar", value_for_field(details: details, field: field1, populate_with_defaults:)
      end

      it "returns nil for the field if not present" do
        assert_nil value_for_field(details: details, field: field2, populate_with_defaults:)
      end

      describe "when details is nil" do
        let(:details) { nil }

        it "returns nil if there is no default value" do
          assert_nil value_for_field(details: details, field: field1, populate_with_defaults:)
        end

        it "returns nil if there is a default value" do
          assert_nil value_for_field(details: details, field: field2, populate_with_defaults:)
        end
      end
    end
  end
end
