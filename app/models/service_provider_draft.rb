class ServiceProviderDraft
  include ActiveModel::Model

  # belongs_to :team, foreign_key: 'group_id', inverse_of: :service_providers
  validates :friendly_name, presence: true, on: [:settings]

  def self.exists?(store)
    store.has_key?(:config_draft)
  end

  def self.find(store)
    new(store, store[:config_draft]) if exists?(store)
  end

  # SimpleForm uses this to pull dropdown options
  def self.reflect_on_association(key)
    ServiceProvider.reflect_on_association(key)
  end

  def initialize(store, attributes = {})
    @attributes = attributes.with_indifferent_access
    @store = store
    @store[:config_draft] = @attributes
  end

  def attributes
    @attributes.with_indifferent_access
  end

  def update(params, step = nil)
    @attributes = params
    if valid?(step)
      @store[:config_draft] = attributes
    else
      false
    end
  end

  def method_missing(name, *args, &block)
    if attributes.has_key?(name)
      attributes[name]
    else
      super
    end
  end
end