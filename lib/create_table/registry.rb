require 'singleton'
module CreateTable
  class Registry < ::Hash
    include ::Singleton
  end
end
