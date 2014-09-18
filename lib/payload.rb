require "scrivener"

class Payload < Scrivener
  attr_accessor :type, :content, :commit_message

  def self.extract(params)
    filter = new(params)

    if filter.valid?
      return params
    else
      raise Invalid, filter.errors
    end

  rescue NoMethodError => err
    raise Invalid, { err.name[0..-2] => [:not_valid] }
  end

  def validate
    assert_present :type
    assert_present :commit_message

    # For the content, we should allow an empty string
    # since someone might want to commit an empty README
    # for example.
    assert !content.nil?, [:content, :not_present]
  end

  class Invalid < StandardError
    attr :errors

    def initialize(errors)
      super()

      @errors = errors
    end
  end

  class Commit < self
    def validate
      assert_present :commit_message
    end
  end
end
