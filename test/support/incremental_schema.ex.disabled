defmodule Absinthe.IncrementalSchema do
  @moduledoc """
  Test schema demonstrating @defer and @stream directive usage.
  
  This schema provides examples of how to use incremental delivery
  with various field types and scenarios.
  """
  
  use Absinthe.Schema
  
  # Import the built-in directives including @defer and @stream
  import_types Absinthe.Type.BuiltIns
  
  @users [
    %{id: "1", name: "Alice", email: "alice@example.com", posts: ["1", "2"]},
    %{id: "2", name: "Bob", email: "bob@example.com", posts: ["3", "4", "5"]},
    %{id: "3", name: "Charlie", email: "charlie@example.com", posts: ["6"]}
  ]
  
  @posts [
    %{id: "1", title: "GraphQL Basics", content: "Introduction to GraphQL...", author_id: "1", comments: ["1", "2"]},
    %{id: "2", title: "Advanced GraphQL", content: "Deep dive into GraphQL...", author_id: "1", comments: ["3"]},
    %{id: "3", title: "Elixir Tips", content: "Best practices for Elixir...", author_id: "2", comments: ["4", "5", "6"]},
    %{id: "4", title: "Phoenix LiveView", content: "Building real-time apps...", author_id: "2", comments: []},
    %{id: "5", title: "Absinthe Guide", content: "Complete guide to Absinthe...", author_id: "2", comments: ["7"]},
    %{id: "6", title: "Testing in Elixir", content: "How to test Elixir apps...", author_id: "3", comments: ["8", "9"]}
  ]
  
  @comments [
    %{id: "1", text: "Great article!", post_id: "1", author_id: "2"},
    %{id: "2", text: "Very helpful", post_id: "1", author_id: "3"},
    %{id: "3", text: "Looking forward to more", post_id: "2", author_id: "2"},
    %{id: "4", text: "Nice tips!", post_id: "3", author_id: "1"},
    %{id: "5", text: "Agreed!", post_id: "3", author_id: "3"},
    %{id: "6", text: "Thanks for sharing", post_id: "3", author_id: "1"},
    %{id: "7", text: "Excellent guide", post_id: "5", author_id: "1"},
    %{id: "8", text: "Very thorough", post_id: "6", author_id: "1"},
    %{id: "9", text: "Helpful examples", post_id: "6", author_id: "2"}
  ]
  
  query do
    @desc "Get a single user by ID"
    field :user, :user do
      arg :id, non_null(:id)
      
      resolve fn %{id: id}, _ ->
        user = Enum.find(@users, &(&1.id == id))
        {:ok, user}
      end
    end
    
    @desc "Get all users - can be streamed"
    field :users, list_of(:user) do
      resolve fn _, _ ->
        # Simulate some processing time
        Process.sleep(100)
        {:ok, @users}
      end
    end
    
    @desc "Get all posts - can be streamed"
    field :posts, list_of(:post) do
      arg :limit, :integer, default_value: 10
      
      resolve fn args, _ ->
        # Simulate database query
        Process.sleep(200)
        posts = Enum.take(@posts, Map.get(args, :limit, 10))
        {:ok, posts}
      end
    end
    
    @desc "Search across all content"
    field :search, :search_result do
      arg :query, non_null(:string)
      
      resolve fn %{query: query}, _ ->
        # Simulate search processing
        Process.sleep(150)
        
        matching_users = Enum.filter(@users, fn user ->
          String.contains?(String.downcase(user.name), String.downcase(query))
        end)
        
        matching_posts = Enum.filter(@posts, fn post ->
          String.contains?(String.downcase(post.title), String.downcase(query)) or
          String.contains?(String.downcase(post.content), String.downcase(query))
        end)
        
        {:ok, %{users: matching_users, posts: matching_posts}}
      end
    end
  end
  
  @desc "User type"
  object :user do
    field :id, non_null(:id)
    field :name, non_null(:string)
    field :email, non_null(:string)
    
    @desc "User's posts - expensive to load, good for @defer"
    field :posts, list_of(:post) do
      resolve fn user, _ ->
        # Simulate expensive database query
        Process.sleep(300)
        posts = Enum.filter(@posts, &(&1.author_id == user.id))
        {:ok, posts}
      end
    end
    
    @desc "User's profile - can be deferred"
    field :profile, :user_profile do
      resolve fn user, _ ->
        # Simulate loading profile data
        Process.sleep(200)
        {:ok, %{
          bio: "Bio for #{user.name}",
          avatar_url: "https://example.com/avatar/#{user.id}",
          joined_at: "2024-01-01"
        }}
      end
    end
  end
  
  @desc "User profile type"
  object :user_profile do
    field :bio, :string
    field :avatar_url, :string
    field :joined_at, :string
  end
  
  @desc "Post type"
  object :post do
    field :id, non_null(:id)
    field :title, non_null(:string)
    field :content, non_null(:string)
    
    @desc "Post author - can be deferred"
    field :author, :user do
      resolve fn post, _ ->
        # Simulate database query
        Process.sleep(100)
        author = Enum.find(@users, &(&1.id == post.author_id))
        {:ok, author}
      end
    end
    
    @desc "Post comments - good for @stream"
    field :comments, list_of(:comment) do
      resolve fn post, _ ->
        # Simulate loading comments
        Process.sleep(50)
        comments = Enum.filter(@comments, &(&1.post_id == post.id))
        {:ok, comments}
      end
    end
    
    @desc "Related posts - expensive, good for @defer"
    field :related_posts, list_of(:post) do
      resolve fn post, _ ->
        # Simulate expensive recommendation algorithm
        Process.sleep(500)
        related = Enum.take(Enum.reject(@posts, &(&1.id == post.id)), 3)
        {:ok, related}
      end
    end
  end
  
  @desc "Comment type"
  object :comment do
    field :id, non_null(:id)
    field :text, non_null(:string)
    
    field :author, :user do
      resolve fn comment, _ ->
        author = Enum.find(@users, &(&1.id == comment.author_id))
        {:ok, author}
      end
    end
  end
  
  @desc "Search result type"
  object :search_result do
    @desc "Matching users - can be deferred"
    field :users, list_of(:user)
    
    @desc "Matching posts - can be deferred"
    field :posts, list_of(:post)
  end
  
  subscription do
    @desc "Subscribe to new posts"
    field :new_post, :post do
      config fn _, _ ->
        {:ok, topic: "posts:new"}
      end
      
      trigger :create_post, topic: fn _ -> "posts:new" end
    end
    
    @desc "Subscribe to comments on a post"
    field :post_comments, :comment do
      arg :post_id, non_null(:id)
      
      config fn %{post_id: post_id}, _ ->
        {:ok, topic: "post:#{post_id}:comments"}
      end
    end
  end
  
  mutation do
    @desc "Create a new post"
    field :create_post, :post do
      arg :title, non_null(:string)
      arg :content, non_null(:string)
      arg :author_id, non_null(:id)
      
      resolve fn args, _ ->
        post = %{
          id: "#{System.unique_integer([:positive])}",
          title: args.title,
          content: args.content,
          author_id: args.author_id,
          comments: []
        }
        {:ok, post}
      end
    end
  end
end