class EditionTypeConstraints
  def initialize(type)
    @type = type
  end

  def matches?(request)
    id = request.path_parameters[:edition_id] || request.path_parameters[:id]
    type = (request.env["edition.type"] ||= V2::Edition.where(id: id).pick(:type))
    type == @type
  end
end
