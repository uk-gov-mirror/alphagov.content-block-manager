RSpec.describe GeneratePreviewHtml do
  include Rails.application.routes.url_helpers

  let(:host_content_id) { SecureRandom.uuid }
  let(:preview_content_id) { SecureRandom.uuid }
  let(:host_title) { "Test" }
  let(:host_base_path) { "/test" }
  let(:uri_mock) { double }

  let(:fake_body) do
    <<-HTML
    <body class=\"govuk-body\">
        <p>test</p>
        <span
          class=\"content-embed content-embed__content_block_contact\"
          data-content-block=\"\"
          data-document-type=\"content_block_contact\"
          data-embed-code=\"embed-code\"
          data-content-id=\"#{preview_content_id}\">example@example.com</span>
      </body>
    HTML
  end

  let(:fake_frontend_response) do
    <<-HTML
      <head>
        <link rel="stylesheet" href="/assets/application.css">
        <script src="/assets/application.js"></script>/
      </head>
      <body class="govuk-body">
        #{fake_body}
      </body>
    HTML
  end

  let(:block_render) do
    "<span class=\"content-embed content-embed__content_block_contact\" data-content-block=\"\" data-document-type=\"content_block_contact\" data-embed-code=\"embed-code\" data-content-id=\"#{preview_content_id}\"><a class=\"govuk-link\" href=\"mailto:new@new.com\">new@new.com</a></span>"
  end

  let(:document) do
    build(:document, :contact, content_id: preview_content_id)
  end

  let(:block_to_preview) do
    build(:edition, :contact, document:, details: { "email_address" => "new@new.com" }, id: 1)
  end

  before do
    allow(Net::HTTP).to receive(:get).with(URI("#{Plek.website_root}#{host_base_path}")).and_return(fake_frontend_response)
    allow(block_to_preview).to receive(:render).and_return(block_render)
  end

  it "returns the preview html" do
    actual_content = GeneratePreviewHtml.new(
      content_id: host_content_id,
      edition: block_to_preview,
      base_path: host_base_path,
      locale: "en",
    ).call

    parsed_content = Nokogiri::HTML.parse(actual_content)

    expect(parsed_content.at_css("body.gem-c-layout-for-public--draft")).to be_present
    expect(parsed_content.at_css('span.content-embed__content_block_contact[style="background-color: yellow;"]')).to be_present
  end

  it "appends the base path to the CSS and JS references" do
    actual_content = GeneratePreviewHtml.new(
      content_id: host_content_id,
      edition: block_to_preview,
      base_path: host_base_path,
      locale: "en",
    ).call

    parsed_content = Nokogiri::HTML.parse(actual_content)

    expect(parsed_content.at_css("link[href='#{Plek.website_root}/assets/application.css']")).to be_present
    expect(parsed_content.at_css("script[src='#{Plek.website_root}/assets/application.js']")).to be_present
  end

  describe "when the frontend throws an error" do
    before do
      exception = StandardError.new("Something went wrong")
      expect(Net::HTTP).to receive(:get).with(URI("#{Plek.website_root}#{host_base_path}")).and_raise(exception)
    end

    it "shows an error template" do
      expected_content = Nokogiri::HTML.parse("<html><head></head><body class=\" gem-c-layout-for-public--draft\"><p>Preview not found</p></body></html>").to_s

      actual_content = GeneratePreviewHtml.new(
        content_id: host_content_id,
        edition: block_to_preview,
        base_path: host_base_path,
        locale: "en",
      ).call

      expect(actual_content).to eq(expected_content)
    end
  end

  describe "when the frontend response contains links" do
    let(:fake_body) do
      "
        <a href='/foo'>Internal link</a>
        <a href='https://example.com'>External link</a>
        <a href='//example.com'>Protocol relative link</a>
      "
    end

    it "updates any link paths" do
      actual_content = GeneratePreviewHtml.new(
        content_id: host_content_id,
        edition: block_to_preview,
        base_path: host_base_path,
        locale: "en",
      ).call

      url = host_content_preview_edition_path(id: block_to_preview.id, host_content_id:)

      parsed_content = Nokogiri::HTML.parse(actual_content)

      internal_link = parsed_content.xpath("//a")[0]
      external_link = parsed_content.xpath("//a")[1]
      protocol_relative_link = parsed_content.xpath("//a")[2]

      expect("#{url}?locale=en&base_path=/foo").to eq(internal_link.attribute("href").to_s)
      expect("_parent").to eq(internal_link.attribute("target").to_s)

      expect("https://example.com").to eq(external_link.attribute("href").to_s)

      expect("//example.com").to eq(protocol_relative_link.attribute("href").to_s)
    end
  end

  describe "when the frontend response contains forms" do
    let(:fake_body) do
      "
        <main>
          <form action='/foo' method='get'>
            <input type='radio' name='foo' />
            <input type='text' name='bar' />
          </form>
        </main>
      "
    end

    it "updates the form and input attributes" do
      actual_content = GeneratePreviewHtml.new(
        content_id: host_content_id,
        edition: block_to_preview,
        base_path: host_base_path,
        locale: "en",
      ).call

      parsed_content = Nokogiri::HTML.parse(actual_content)

      form = parsed_content.css("main form")[0]
      inputs = form.css("input")

      form_handler_path = host_content_preview_form_handler_edition_path(
        id: block_to_preview.id,
        host_content_id: host_content_id,
        locale: "en",
      )
      expected_url = "#{Plek.website_root}/foo"
      expected_action = "#{form_handler_path}&url=#{expected_url}&method=get"

      expect(form[:action]).to eq(expected_action)
      expect(form[:target]).to eq("_parent")
      expect(form[:method]).to eq("post")

      expect(inputs[0][:name]).to eq("body[foo]")
      expect(inputs[1][:name]).to eq("body[bar]")
    end
  end

  describe "when the wrapper is a div" do
    let(:fake_body) do
      "<p>test</p><div class=\"content-embed content-embed__content_block_contact\" data-content-block=\"\" data-document-type=\"content_block_contact\" data-embed-code=\"embed-code\" data-content-id=\"#{preview_content_id}\">example@example.com</div>"
    end
    let(:block_render) do
      "<div class=\"content-embed content-embed__content_block_contact\" data-content-block=\"\" data-document-type=\"content_block_contact\" data-embed-code=\"embed-code\" data-content-id=\"#{preview_content_id}\"><a class=\"govuk-link\" href=\"mailto:new@new.com\">new@new.com</a></div>"
    end

    it "returns the preview html" do
      actual_content = GeneratePreviewHtml.new(
        content_id: host_content_id,
        edition: block_to_preview,
        base_path: host_base_path,
        locale: "en",
      ).call

      parsed_content = Nokogiri::HTML.parse(actual_content)

      expect(parsed_content.at_css("body.gem-c-layout-for-public--draft")).to be_present
      expect(parsed_content.at_css('div.content-embed__content_block_contact[style="background-color: yellow;"]')).to be_present
    end
  end

  describe "when in development mode" do
    let(:rendering_app) { "government-frontend" }
    let(:publishing_api_response) do
      {
        "foo" => "bar",
        "rendering_app" => rendering_app,
      }
    end

    before do
      allow(Rails.env).to receive(:development?).and_return(true)
      allow(Services.publishing_api).to receive(:get_content).with(host_content_id).and_return(publishing_api_response)
    end

    it "makes a request to the rendering app as reported by the Publishing API" do
      expect(Net::HTTP).to receive(:get).with(URI("#{Plek.external_url_for(rendering_app)}#{host_base_path}")).and_return(fake_frontend_response)

      GeneratePreviewHtml.new(
        content_id: host_content_id,
        edition: block_to_preview,
        base_path: host_base_path,
        locale: "en",
      ).call
    end

    describe "when the Publishing API does not report a rendering app" do
      let(:publishing_api_response) do
        {
          "foo" => "bar",
        }
      end

      it "defaults to frontend" do
        expect(Net::HTTP).to receive(:get).with(URI("#{Plek.external_url_for('frontend')}#{host_base_path}")).and_return(fake_frontend_response)

        GeneratePreviewHtml.new(
          content_id: host_content_id,
          edition: block_to_preview,
          base_path: host_base_path,
          locale: "en",
        ).call
      end
    end

    describe "when the frontend app is smart answers" do
      let(:rendering_app) { "smartanswers" }

      it "makes a request to smart-answers" do
        expect(Net::HTTP).to receive(:get).with(URI("#{Plek.external_url_for('smart-answers')}#{host_base_path}")).and_return(fake_frontend_response)

        GeneratePreviewHtml.new(
          content_id: host_content_id,
          edition: block_to_preview,
          base_path: host_base_path,
          locale: "en",
        ).call
      end
    end
  end
end
