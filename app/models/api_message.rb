class ApiMessage
  def initialize(attributes = {})
    @attributes = attributes.transform_keys(&:to_sym)
    @attributes[:id] ||= SecureRandom.uuid
  end

  def id
    @attributes[:id]
  end

  def as_json(*_args)
    @attributes
  end

  def method_missing(method, *args, &block)
    if @attributes.key?(method)
      @attributes[method]
    else
      super
    end
  end

  def respond_to_missing?(method, include_private = false)
    @attributes.key?(method) || super
  end
end
