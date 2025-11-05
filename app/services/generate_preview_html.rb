require "net/http"
require "json"
require "uri"

class GeneratePreviewHtml
  include Rails.application.routes.url_helpers

  def initialize(content_id:, edition:, base_path:, locale:)
    @content_id = content_id
    @edition = edition
    @base_path = base_path
    @locale = locale
  end

  def call
    uri = URI(frontend_path)
    nokogiri_html = html_snapshot_from_frontend(uri)
    update_local_link_paths(nokogiri_html)
    update_local_form_actions(nokogiri_html, uri.scheme, uri.host)
    add_draft_style(nokogiri_html)
    update_css_hrefs(nokogiri_html)
    update_js_srcs(nokogiri_html)
    replace_existing_content_blocks(nokogiri_html).to_s
  end

private

  BLOCK_STYLE = "background-color: yellow;".freeze
  ERROR_HTML = "<html><head></head><body><p>Preview not found</p></body></html>".freeze

  attr_reader :edition, :content_id, :base_path, :locale

  def frontend_path
    frontend_base_path + base_path
  end

  def frontend_base_path
    @frontend_base_path ||= Rails.env.development? ? development_base_path : Plek.website_root
  end

  # There are multiple rendering apps for GOV.UK. In non-dev environments, the Router app determines the rendering app
  # to use. We don't have access to this in dev, so we need to get the rendering app from the Publishing API and construct
  # the base path that way.
  def development_base_path
    @development_base_path ||= begin
      publishing_api_response = Services.publishing_api.get_content(content_id)
      Plek.external_url_for(rendering_app(publishing_api_response))
    end
  end

  def rendering_app(publishing_api_response)
    rendering_app = publishing_api_response["rendering_app"] || "frontend"
    if rendering_app == "smartanswers"
      "smart-answers"
    else
      rendering_app
    end
  end

  def html_snapshot_from_frontend(uri)
    begin
      raw_html = Net::HTTP.get(uri)
    rescue StandardError
      raw_html = ERROR_HTML
    end
    Nokogiri::HTML.parse(raw_html)
  end

  def update_local_link_paths(nokogiri_html)
    url = host_content_preview_edition_path(id: edition.id, host_content_id: content_id, locale:)
    nokogiri_html.css("a").each do |link|
      next if link[:href].start_with?("//") || link[:href].start_with?("http")

      link[:href] = "#{url}&base_path=#{link[:href]}"
      link[:target] = "_parent"
    end

    nokogiri_html
  end

  def update_local_form_actions(nokogiri_html, scheme, host)
    url = host_content_preview_form_handler_edition_path(id: edition.id, host_content_id: content_id, locale:)
    nokogiri_html.css("main form").each do |form|
      form[:action] = "#{url}&url=#{scheme}://#{host}#{form[:action]}&method=#{form[:method]}"
      form[:target] = "_parent"
      form[:method] = "post"
      form.css("input").each do |input|
        input[:name] = "body[#{input[:name]}]"
      end
    end

    nokogiri_html
  end

  def add_draft_style(nokogiri_html)
    nokogiri_html.css("body").each do |body|
      body["class"] ||= ""
      body["class"] += " gem-c-layout-for-public--draft"
    end
    nokogiri_html
  end

  def update_css_hrefs(nokogiri_html)
    head = nokogiri_html.at_css("head")
    head.css("link[rel='stylesheet']").each do |link|
      link[:href] = frontend_base_path + link[:href] if link[:href]
    end
    nokogiri_html
  end

  def update_js_srcs(nokogiri_html)
    head = nokogiri_html.at_css("head")
    head.css("script").each do |script|
      script[:src] = frontend_base_path + script[:src] if script[:src]
    end
    nokogiri_html
  end

  def replace_existing_content_blocks(nokogiri_html)
    replace_blocks(nokogiri_html)
    style_blocks(nokogiri_html)
    nokogiri_html
  end

  def replace_blocks(nokogiri_html)
    content_block_wrappers(nokogiri_html).each do |wrapper|
      embed_code = wrapper["data-embed-code"]
      wrapper.replace edition.render(embed_code)
    end
  end

  def style_blocks(nokogiri_html)
    content_block_wrappers(nokogiri_html).each do |wrapper|
      wrapper["style"] = BLOCK_STYLE
    end
  end

  def content_block_wrappers(nokogiri_html)
    nokogiri_html.css("[data-content-id=\"#{@edition.document.content_id}\"]")
  end
end
