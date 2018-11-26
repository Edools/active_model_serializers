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
          tag_name =
            if association.reflection.is_a?(HasManyReflection)
              object = association.object.first
              object.is_a?(Integer) ? association.key.to_s.gsub(/(_ids|_id)$/, '') : object.class.to_s
            else
              association.object.class.to_s
            end

          build_tags_from(association.object, tag_name, association.reflection.options[:tag_method])
        end
      end

      def build_tags_from(object, tag_name, tag_method)
        return tag_method.arity > 0 ? instance_exec(object, &tag_method) : instance_exec(&tag_method) if tag_method
        [object].flatten.map { |obj| build_object_tag(obj, tag_name) }
      end

      def build_object_tag(obj, tag_name)
        id = obj.try(:id) || obj
        [self.class.name.underscore, tag_name.underscore, id].join('/')
      end
    end
  end
end
