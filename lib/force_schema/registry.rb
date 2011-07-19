require 'singleton'
module ForceSchema
  class Registry < ::Hash
    include ::Singleton
  end
end
