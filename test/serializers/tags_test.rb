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
        has_many :blog_ids, tag_method: ->(virtual) { virtual.map{ |id| "foo_#{id}" } }
      end

      class PostSerializer < ActiveModel::Serializer
        has_many :comments, serializer: CommentSerializer
        belongs_to :author, serializer: AuthorSerializer1
      end

      def add_test_prefix(tag)
        'active_model/serializer/tags_test/' + tag
      end

      def setup
        @author  = ARModels::Author.create!(name: 'Homer S.')
        @post    = Post.new(id: 2, title: 'New Post', author: @author)
        @comment = Comment.new(id: 3, body: 'A COMMENT', post: @post)
        @blog    = ARModels::Blog.create!(name: 'awesome_blog')

        @post.comments = [@comment]
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
          add_test_prefix("author_serializer2/ar_models/blog/#{@blog.id}")
        ]

        assert_match_array(expected_tags_1, serializer_1._tags)
        assert_match_array(expected_tags_2, serializer_2._tags)
      end

      def test_tags_with_belongs_to_and_has_many
        serializer = PostSerializer.new(@post)
        expected_tags = [
          add_test_prefix("post_serializer/post/#{@post.id}"),
          add_test_prefix("post_serializer/comment/#{@comment.id}"),
          add_test_prefix("post_serializer/ar_models/author/#{@author.id}")
        ]

        assert_match_array(expected_tags, serializer._tags)
      end

      def test_tags_with_belongs_to_and_tag_method
        serializer = CommentSerializer.new(@comment)
        expected_tags = [
          "post_#{@post.id}",
          add_test_prefix("comment_serializer/comment/#{@comment.id}")
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
    end
  end
end
