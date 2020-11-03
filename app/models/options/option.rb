class Options::Option
  include Mongoid::Document
  include Mongoid::Timestamps

  field :key, type: Symbol
  field :namespace, type: Boolean, default: true

  field :title, type: String
  field :description, type: String
  field :type, type: Symbol
  field :default, type: String
  field :value, type: String
  field :choices, type: Array
  field :content_type, type: String
  field :is_active, type: Boolean

  field :aria_label, type: String

  recursively_embeds_many

  accepts_nested_attributes_for :child_options

  embedded_in :configurable, polymorphic: true

  scope :by_key, ->(key) { where(key: key) }

  def options
    child_options
  end

  def namespaces
    child_options.select(&:namespace)
  end

  def settings
    child_options.collect(&:setting_hash)
  end

  def setting_hash
    {
      key: key,
      title: title,
      description: description,
      type: type,
      value: value || default,
      is_active: is_active
    }
  end

  def supported_languages=(val)
    site     = Sites::Site.where('options._id'=> self.id).first
    language = site.tenant.languages.options.where(key: val.to_sym).first

    if child_options.by_key(language.key).blank?
      child_options.build(key: language.key, title: language.title, type: language.type)
    end
  end

  def settings=(params)
    params.each {|param_hash| child_options.build(param_hash.merge(namespace: false)) }
  end

  def namespaces=(params)
    params.each {|param_hash| child_options.build(param_hash) }
  end

  def value=(assignment)
    return super(assignment) unless type == :base_64

    self.content_type = assignment.content_type
    file = assignment.read.force_encoding(Encoding::UTF_8)

    super(Base64.strict_encode64(file))
  end

  def to_h
    if child_options.present?
      options_hash = child_options.inject({}) do |data, option|
        if option.to_h.has_key?(option.key)
          data.merge(option.to_h)
        else
          data[option.key] = option.to_h; data
        end
      end

      {:"#{key}" => options_hash}
    else
      setting_hash
    end
  end
end
