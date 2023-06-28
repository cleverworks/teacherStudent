class Grade
  include Mongoid::Document
  include Mongoid::Timestamps

  FIELDSET = %w(title descr metaData).freeze

  # Mapped Fields
  field :title, type: String
  field :descr, type: String
  field :metaData, type: Hash

  has_many :subjects, dependent: :destroy
  
  # Validations
  validates :title, presence: true, uniqueness: true
end
