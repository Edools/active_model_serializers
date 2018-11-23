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
          serializer = association.serializer

          if serializer.respond_to?(:each)
            serializer.map { |s| s._tags }
          elsif association.options[:virtual_value]
            tags_for_virtual_value_from(association)
          else
            serializer._tags
          end
        end
      end

      def tags_for_virtual_value_from(association)
        name = association.name.to_s
        virtual_value = association.options[:virtual_value]

        if association.options[:tag_method]
          meth = association.options[:tag_method]
          meth.arity > 0 ? instance_exec(virtual_value, &meth) : instance_exec(&meth)
        elsif name.end_with?('_ids', 'id')
          tag_name = name.gsub(/(_ids|_id)$/, '')

          virtual_value.map do |id|
            [self.class.name.underscore, tag_name, id].join('/')
          end
        else
          raise "You need to provide the `tag_method` option for `#{name}` association"
        end
      end
    end
  end
end
