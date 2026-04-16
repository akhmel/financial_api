module Monetizable
  extend ActiveSupport::Concern

  class_methods do
    def money_as_decimal(*attributes)
      attributes.each do |attr|
        define_method(:"#{attr}_decimal") do
          public_send(attr).to_f
        end
      end
    end
  end
end
