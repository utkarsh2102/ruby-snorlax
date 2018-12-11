require 'snorlax/version'
require 'snorlax/engine'

module Snorlax
end

class ActionController::Base
  # Method to allow controllers to apply Snorlax to themselves
  # (g@nked from Inherited resources: https://github.com/josevalim/inherited_resources/blob/master/lib/inherited_resources.rb)
  def self.snorlax_used_rest!
    Snorlax::Base.snorlax_used_rest!(self)
  end
end
