module HasManyPublicKeys
  extend ActiveSupport::Concern

  included do
    has_many :public_keys
  end
end