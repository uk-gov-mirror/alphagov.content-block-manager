desc "Delete content block"
task :delete_content_block, [:content_id] => :environment do |_t, args|
  content_id = args[:content_id]
  document = Document.find_by(content_id:)

  abort("A content block with the content ID `#{content_id}` cannot be found") unless document

  @host_content_items = HostContentItem.for_document(document)

  abort("Content block `#{content_id}` cannot be deleted because it has host content. Try removing the dependencies and trying again") unless @host_content_items.items.count.zero?

  Services.publishing_api.unpublish(
    content_id,
    type: "vanish",
    locale: "en",
    discard_drafts: true,
  )

  document.soft_delete

  if ENV["RAILS_ENV"] != "test"
    puts "Content block `#{content_id}` has been deleted."
  end
end
