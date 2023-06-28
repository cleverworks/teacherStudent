class Subject
  include Mongoid::Document
  include Mongoid::Timestamps

  VALID_STATUSES = {
    draft: "DRAFT",
    published: "PUBLISHED"
  }.freeze

  FIELDSET = %w(title credits credits grade_id metaData).freeze

  # Mapped Fields
  field :title, type: String
  field :descr, type: String
  field :credits, type: Float
  field :metaData, type: Hash
  field :published, type: Boolean, default: false

  belongs_to :grade, inverse_of: :subjects
  has_many :chapters, dependent: :destroy, inverse_of: :subject

  # Validations
  validates :title, presence: true
  validates :credits, presence: true, numericality: { greater_than_or_equal_to: 0.0, less_than_or_equal_to: 5.0, only_integer: false, step: 0.5 }
end
