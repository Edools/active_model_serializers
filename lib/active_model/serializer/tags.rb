module ActiveModel
  class Serializer
    module Tags
      extend ActiveSupport::Concern

      def _tags
        if object.present?
          associations_tags.push(object_tag).flatten.compact.uniq
        end
      end

      private

      def object_tag
        [self.class.name.underscore, object.class.name.underscore, object.id].join('/')
      end

      def associations_tags
        associations.map do |association|
          tag_name = association.key.to_s.singularize.gsub(/(_id)$/, '')
          build_tags_from(association.object, tag_name, association.reflection.options)
        end
      end

      def build_tags_from(object, tag_name, options)
        tag_method = options[:tag_method]
        return tag_method.arity > 0 ? instance_exec(object, &tag_method) : instance_exec(&tag_method) if tag_method

        [object].flatten.map { |obj| build_object_tag(obj, tag_name, options[:serializer]) }
      end

      def build_object_tag(obj, tag_name, custom_serializer)
        id = obj.try(:id) || obj
        # binding.pry if ENV['foo']

        serializer = custom_serializer || self.class
        [serializer.name.underscore, tag_name.underscore, id].join('/')
      end
    end
  end
end
