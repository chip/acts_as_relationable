module ActiveRecord
  module Acts #:nodoc:
    module Relationable #:nodoc:
      
      MODELS = Dir[RAILS_ROOT + "/app/models/*.rb"].collect { |f| File.basename f, '.rb' }
      
      def self.included(base)
        base.extend ClassMethods
      end

      module ClassMethods
        def acts_as_relationable(*types)
          if types.empty? # Relationship model            
            belongs_to :user

            belongs_to :parent, :polymorphic => true
            belongs_to :child,  :polymorphic => true
            
            MODELS.each do |m|
              belongs_to "parent_#{m}".intern, :foreign_key => 'parent_id', :class_name => m.camelize
              belongs_to "child_#{m}".intern,  :foreign_key => 'child_id',  :class_name => m.camelize
            end
          else
            options = types.last.respond_to?(:keys) ? types.pop : {}
            fields  = options[:fields] || []
            fields  = [ fields ] unless fields.respond_to?(:flatten)

            has_many :parent_relationships, :class_name => 'Relationship', :as => :child
            has_many :child_relationships,  :class_name => 'Relationship', :as => :parent
          
            types.each do |type|
              type   = type.to_s
              select = "#{type}.*#{fields.empty? ? '' : ', '}" + fields.collect { |f| "relationships.#{f}" }.join(', ')
            
              has_many 'parent_' + type,
                :select  => select, :through => :parent_relationships,
                :source => :parent, :source_type => type.singularize.camelize
            
              has_many 'child_' + type,
                :select  => select, :through => :child_relationships,
                :source => :child,  :source_type => type.singularize.camelize
              
              self.class_eval do
                define_method type do
                  if self.class.to_s < type.singularize.camelize
                    eval "self.child_#{type}"
                  else
                    eval "self.parent_#{type}"
                  end
                end
              end
            end
          end
          
          include ActiveRecord::Acts::Relationable::InstanceMethods
          extend  ActiveRecord::Acts::Relationable::SingletonMethods
        end
      end

      module SingletonMethods
      end

      module InstanceMethods
      end
    end
  end
end