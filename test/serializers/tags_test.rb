require 'test_helper'

module ActiveModel
  class Serializer
    class TagsTest < Minitest::Test
      class CommentTestSerializer < Serializer
        attributes :id
        belongs_to :post, tag_method: -> { "post_#{object.post.id}" }

        def post
          { awesome_post: object.post }
        end
      end

      class AuthorTestSerializer < Serializer
        has_many :blog_ids
      end

      class AuthorWithMethTagTestSerializer < Serializer
        has_many :blog_ids, tag_method: ->(virtual) { virtual.map{ |id| "foo_#{id}" } }
      end

      class PostTestSerializer < Serializer
        has_many :comments, serializer: CommentTestSerializer
        belongs_to :author, serializer: AuthorTestSerializer
      end

      def add_test_prefix(tag)
        'active_model/serializer/tags_test/' + tag
      end

      def setup
        @author = ARModels::Author.create(name: 'Homer S.')
        @post = Post.new(id: 2, title: 'New Post', author: @author, comments: [@post])
        @comment = Comment.new(id: 3, body: 'A COMMENT', post: @post)
        @blog = ARModels::Blog.create(name: 'awesome_blog')

        @author.blogs << @blog
      end

      def test_tags
        @serializer = PostTestSerializer.new(@post)

        expected_tags = []
        expected_tags << add_test_prefix("author_test_serializer/blog/#{@blog.id}")
        expected_tags << add_test_prefix("author_test_serializer/ar_models/author/#{@author.id}")
        expected_tags << add_test_prefix("post_test_serializer/post/2")

        assert_equal(expected_tags, @serializer._tags)
      end

      def test_tag_with_virtual_attribute
        serializer = AuthorTestSerializer.new(@author)

        expected_tags = []
        expected_tags << add_test_prefix("author_test_serializer/blog/#{@blog.id}")
        expected_tags << add_test_prefix("author_test_serializer/ar_models/author/#{@author.id}")

        assert_equal(expected_tags, serializer._tags)
      end

      def test_tag_with_virtual_attribute_and_tag_method
        serializer = CommentTestSerializer.new(@comment)

        expected_tags = []
        expected_tags << 'post_2'
        expected_tags << add_test_prefix('comment_test_serializer/comment/3')

        assert_equal(expected_tags, serializer._tags)
      end

      def test_tag_using_virtual_attribute_with_tag_method
        serializer = AuthorWithMethTagTestSerializer.new(@author)

        expected_tags = []
        expected_tags << "foo_#{@blog.id}"
        expected_tags << add_test_prefix("author_with_meth_tag_test_serializer/ar_models/author/#{@author.id}")

        assert_equal(expected_tags, serializer._tags)
      end
    end
  end
end
