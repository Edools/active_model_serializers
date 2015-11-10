require 'active_record'

ActiveRecord::Base.establish_connection(adapter: 'sqlite3', database: ':memory:')
ActiveRecord::Schema.define do
  create_table :posts, force: true do |t|
    t.string :title
    t.text :body
    t.references :author
    t.timestamps null: false
  end
  create_table :authors, force: true do |t|
    t.string :name
    t.timestamps null: false
  end
  create_table :comments, force: true do |t|
    t.text :contents
    t.references :author
    t.references :post
    t.timestamp null: false
  end
  create_table :blogs, force: true do |t|
    t.string :name
    t.timestamps null: false
  end
  create_table :authors_blogs, id: false, force: true do |t|
    t.references :author
    t.references :blog
    t.timestamp null: false
  end
end

module ARModels
  class Post < ActiveRecord::Base
    has_many :comments
    belongs_to :author
  end

  class Comment < ActiveRecord::Base
    belongs_to :post
    belongs_to :author
  end

  class Author < ActiveRecord::Base
    has_many :posts
    has_many :comments
    has_and_belongs_to_many :blogs
  end

  class Blog < ActiveRecord::Base
    has_and_belongs_to_many :authors
  end

  class PostSerializer < ActiveModel::Serializer
    attributes :id, :title, :body

    has_many :comments
    belongs_to :author
  end

  class CommentSerializer < ActiveModel::Serializer
    attributes :id, :contents

    belongs_to :author
  end

  class AuthorSerializer < ActiveModel::Serializer
    attributes :id, :name

    has_many :posts
  end
end
