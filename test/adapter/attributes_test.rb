require 'test_helper'

module ActiveModelSerializers
  module Adapter
    class AttributesTest < ActiveSupport::TestCase
      def setup
        ActionController::Base.cache_store.clear
      end

      def serializable_hash_for(serializer, options = {})
        adapter = ActiveModelSerializers::Adapter::Attributes.new(serializer, options)
        adapter.serializable_hash
      end

      class AdapterTest < AttributesTest
        class Person < ActiveModelSerializers::Model
          attributes :first_name, :last_name
        end

        class PersonSerializer < ActiveModel::Serializer
          attributes :first_name, :last_name
        end

        def test_serializable_hash
          person = Person.new(first_name: 'Arthur', last_name: 'Dent')
          serializer = PersonSerializer.new(person)
          adapter = ActiveModelSerializers::Adapter::Attributes.new(serializer)

          assert_equal({ first_name: 'Arthur', last_name: 'Dent' },
            adapter.serializable_hash)
        end

        def test_serializable_hash_with_transform_key_casing
          person = Person.new(first_name: 'Arthur', last_name: 'Dent')
          serializer = PersonSerializer.new(person)
          adapter = ActiveModelSerializers::Adapter::Attributes.new(
            serializer,
            key_transform: :camel_lower
          )

          assert_equal({ firstName: 'Arthur', lastName: 'Dent' },
            adapter.serializable_hash)
        end
      end

      class CacheTest < AttributesTest
        class CommentSerializer1 < ActiveModel::Serializer
          attributes :id, :body
        end

        class CommentSerializer2 < ActiveModel::Serializer
          attributes :id, :body
          belongs_to :author
        end

        class PostSerializer1 < ActiveModel::Serializer
          attributes :id, :title
          has_many :comments, include: :author, serializer: CommentSerializer1
          belongs_to :author
        end

        class PostSerializer2 < ActiveModel::Serializer
          attributes :id, :title
          has_many :comments, include: :author, serializer: CommentSerializer2
          belongs_to :author
        end

        class PostSerializer3 < ActiveModel::Serializer
          attributes :id, :title
          has_many :comments, serializer: CommentSerializer2
          belongs_to :author
        end

        def setup
          first_author   = Author.new(id: 1, name: 'Marge S.')
          second_author  = Author.new(id: 2, name: 'Homer S.')
          post           = Post.new(id: 1, title: 'New Post')
          comment        = Comment.new(id: 1, body: 'A COMMENT')
          post.comments  = [comment]
          comment.post   = post
          comment.author = second_author
          post.author    = first_author
          @serializer1   = PostSerializer1.new(post)
          @serializer2   = PostSerializer2.new(post)
          @serializer3   = PostSerializer3.new(post)
        end

        def test_association_include
          post_hash_1 = {
            id: 1,
            title: 'New Post',
            comments: [{ id: 1, body: 'A COMMENT' }],
            author: { id: 1, name: 'Marge S.' }
          }
          post_hash_2 = {
            id: 1,
            title: 'New Post',
            comments: [{ id: 1, body: 'A COMMENT', author: { id: 2, name: 'Homer S.' } }],
            author: { id: 1, name: 'Marge S.' }
          }

          assert_equal(post_hash_1, serializable_hash_for(@serializer1))
          assert_equal(post_hash_1, serializable_hash_for(@serializer3))
          assert_equal(post_hash_2, serializable_hash_for(@serializer2))
          assert_equal(post_hash_2, serializable_hash_for(@serializer2))
        end

        def test_overwriting_association_include
          post_hash = {
            id: 1,
            title: 'New Post',
            author: { id: 1, name: 'Marge S.' }
          }

          assert_equal(post_hash, serializable_hash_for(@serializer2, include: :author))
        end
      end
    end
  end
end
