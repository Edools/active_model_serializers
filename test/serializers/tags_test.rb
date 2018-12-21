require 'test_helper'

module ActiveModel
  class Serializer
    class TagsTest < ActiveSupport::TestCase
      class CommentSerializer < ActiveModel::Serializer
        attributes :id
        belongs_to :post, tag_method: -> { "post_#{object.post.id}" }

        def post
          { awesome_post: object.post }
        end
      end

      class AuthorSerializer1 < ActiveModel::Serializer
        has_many :blog_ids
      end

      class AuthorSerializer2 < ActiveModel::Serializer
        has_many :blogs
      end

      class AuthorSerializerWithTagMethod < ActiveModel::Serializer
        has_many :blog_ids, tag_method: ->(ids) { ids.map{ |id| "foo_#{id}" } }
      end

      class PostSerializer1 < ActiveModel::Serializer
        has_many :comments, serializer: CommentSerializer
        belongs_to :author, serializer: AuthorSerializer1
      end

      class PostSerializer2 < ActiveModel::Serializer
        belongs_to :author_id
        has_many :comment_ids
      end

      class PostSerializer3 < ActiveModel::Serializer
        has_many :comment_ids, tag_method: ->(ids) { ids.map{ |id| "bar_#{id}" } }
        belongs_to :author_id, tag_method: ->(id) { "foo_#{id}" }
      end

      module PostScope
        class CommentSerializer < ActiveModel::Serializer
          attributes :id
        end

        class AuthorSerializer < ActiveModel::Serializer
          attributes :id
        end
      end

      class PostSerializer4 < ActiveModel::Serializer
        has_many :comments, serializer: PostScope::CommentSerializer
        belongs_to :author, serializer: PostScope::AuthorSerializer
      end

      def add_test_prefix(tag)
        'active_model/serializer/tags_test/' + tag
      end

      def setup
        @author       = ARModels::Author.create!(name: 'Homer S.')
        @post_fake    = Post.new(id: 2, title: 'New Post 1', author: @author)
        @comment_fake = Comment.new(id: 3, body: 'A COMMENT', post: @post_fake)
        @post_db      = ARModels::Post.create!(title: 'New Post 2', author: @author)
        @comment_db   = ARModels::Comment.create!(contents: 'A COMMENT', post: @post_db)
        @blog         = ARModels::Blog.create!(name: 'awesome_blog')

        @post_fake.comments = [@comment_fake]
        @author.blogs << @blog
      end

      def test_tags_with_has_many
        serializer_1 = AuthorSerializer1.new(@author)
        serializer_2 = AuthorSerializer2.new(@author)
        expected_tags_1 = [
          add_test_prefix("author_serializer1/ar_models/author/#{@author.id}"),
          add_test_prefix("author_serializer1/blog/#{@blog.id}")
        ]
        expected_tags_2 = [
          add_test_prefix("author_serializer2/ar_models/author/#{@author.id}"),
          add_test_prefix("author_serializer2/blog/#{@blog.id}")
        ]

        assert_match_array(expected_tags_1, serializer_1._tags)
        assert_match_array(expected_tags_2, serializer_2._tags)
      end

      def test_tags_with_belongs_to_and_tag_method
        serializer = CommentSerializer.new(@comment_fake)
        expected_tags = [
          "post_#{@post_fake.id}",
          add_test_prefix("comment_serializer/comment/#{@comment_fake.id}")
        ]

        assert_match_array(expected_tags, serializer._tags)
      end

      def test_tags_with_has_many_and_tag_method
        serializer = AuthorSerializerWithTagMethod.new(@author)
        expected_tags = [
          "foo_#{@blog.id}",
          add_test_prefix("author_serializer_with_tag_method/ar_models/author/#{@author.id}")
        ]

        assert_match_array(expected_tags, serializer._tags)
      end

      def test_tags
        serializer_1 = PostSerializer1.new(@post_fake)
        serializer_2 = PostSerializer1.new(@post_db)
        serializer_3 = PostSerializer2.new(@post_db)
        serializer_4 = PostSerializer3.new(@post_db)
        serializer_5 = PostSerializer4.new(@post_db)
        expected_tags_1 = [
          add_test_prefix("post_serializer1/post/#{@post_fake.id}"),
          add_test_prefix("author_serializer1/author/#{@author.id}"),
          add_test_prefix("comment_serializer/comment/#{@comment_fake.id}")
        ]
        expected_tags_2 = [
          add_test_prefix("post_serializer1/ar_models/post/#{@post_db.id}"),
          add_test_prefix("author_serializer1/author/#{@author.id}"),
          add_test_prefix("comment_serializer/comment/#{@comment_db.id}")
        ]
        expected_tags_3 = [
          add_test_prefix("post_serializer2/ar_models/post/#{@post_db.id}"),
          add_test_prefix("post_serializer2/author/#{@author.id}"),
          add_test_prefix("post_serializer2/comment/#{@comment_db.id}")
        ]
        expected_tags_4 = [
          add_test_prefix("post_serializer3/ar_models/post/#{@post_db.id}"),
          "foo_#{@author.id}",
          "bar_#{@comment_db.id}"
        ]
        expected_tags_5 = [
          add_test_prefix("post_serializer4/ar_models/post/#{@post_db.id}"),
          add_test_prefix("post_scope/author_serializer/author/#{@author.id}"),
          add_test_prefix("post_scope/comment_serializer/comment/#{@comment_db.id}")
        ]

        ENV['foo'] = 't'
        assert_match_array(expected_tags_1, serializer_1._tags)
        assert_match_array(expected_tags_2, serializer_2._tags)
        assert_match_array(expected_tags_3, serializer_3._tags)
        assert_match_array(expected_tags_4, serializer_4._tags)
        assert_match_array(expected_tags_5, serializer_5._tags)
      end
    end
  end
end
