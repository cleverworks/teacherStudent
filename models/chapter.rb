class Chapter
  include Mongoid::Document
  include Mongoid::Timestamps

  FIELDSET = %w(title descr subject_id metaData).freeze

  # Mapped Fields
  field :title, type: String
  field :descr, type: String
  field :descr, type: String
  field :metaData, type: Hash

  belongs_to :subject, inverse_of: :chapters
end
