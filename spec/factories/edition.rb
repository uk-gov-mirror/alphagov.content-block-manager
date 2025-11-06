FactoryBot.define do
  factory :edition, class: "Edition" do
    details { {} }
    created_at { Time.zone.now.utc }
    updated_at { Time.zone.now.utc }
    schema { build(:schema) }
    creator { build(:user) }

    lead_organisation_id { SecureRandom.uuid }

    document_id { nil }

    scheduled_publication { nil }

    instructions_to_publishers { nil }

    title { "Factory Title for Edition" }

    internal_change_note { "Something changed" }

    change_note { "Something changed publicly" }

    major_change { true }

    Schema.valid_schemas.each do |type|
      trait type.to_sym do
        after(:build) do |edition, _evaluator|
          unless edition.document_id || edition.document
            edition.document = build(:document, block_type: type)
          end
        end
      end
    end

    trait :latest do
      after(:create) do |edition, _evaluator|
        document_update_params = {
          latest_edition_id: edition.id,
        }
        edition.document.update!(document_update_params)
      end
    end
  end
end
