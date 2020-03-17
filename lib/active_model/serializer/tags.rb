module ActiveModel
  class Serializer
    module Tags
      extend ActiveSupport::Concern

      def _tags
        build_tags if object.present?
      end

      def build_tags(serializer_class = self.class, object = self.object, tag_name = nil, options = {}, parent_serializer = nil, associations_includes = nil)
        serializer = serializer_class.new(object, self.instance_options) if serializer_class
        return [build_tag(serializer, object, tag_name, options, parent_serializer)] if serializer.blank? || serializer.associations.blank?

        associations_tags = serializer.associations.map do |asc|
          parent_serializer = asc.association_options[:parent_serializer]
          serializer_klass = asc.reflection.options[:serializer]
          tag_name = asc.key.to_s.singularize.gsub(/(_id)$/, '')
          options = asc.reflection.options
          associations_to_include = [options[:include]].flatten

          next if associations_includes && (associations_includes.blank? || !associations_includes.include?(asc.key))

          if asc.object.respond_to?(:each) && !options[:tag_method]
            asc.object.map { |obj| build_tags(serializer_klass, obj, tag_name, options, parent_serializer, associations_to_include) }
          else
            build_tags(serializer_klass, asc.object, tag_name, options, parent_serializer, associations_to_include)
          end
        end

        associations_tags.flatten.compact << build_tag(serializer, object, tag_name, options, parent_serializer)
      end

      def build_tag(serializer, object, tag_name, options, parent_serializer)
        if serializer
          serializer.object_tag
        else
          build_tags_from(object, tag_name, options, parent_serializer)
        end
      end

      def object_tag
        return if object.blank?
        [self.class.name.underscore, object.class.name.underscore, object.id].join('/')
      end

      private

      def build_tags_from(object, tag_name, options, parent_serializer)
        tag_method = options[:tag_method]
        return tag_method.arity > 0 ? instance_exec(object, &tag_method) : instance_exec(&tag_method) if tag_method

        serializer_class = options[:serializer] || parent_serializer.class || self.class
        [object].flatten.map { |obj| build_object_tag(obj, tag_name, serializer_class) }
      end

      def build_object_tag(obj, tag_name, serializer_class)
        id = obj.try(:id) || obj
        [serializer_class.name.underscore, tag_name.underscore, id].join('/')
      end
    end
  end
end
