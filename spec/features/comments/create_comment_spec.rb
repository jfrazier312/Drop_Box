require 'rails_helper.rb'
require 'helpers/spec_test_helpers.rb'
require 'pry';


RSpec.describe "Creating Comments Feature Test", :type => :feature do

  before :each do
    login(:user_admin)
    @post = FactoryGirl.create(:post)
  end

  after :each do |example|
    unless example.metadata[:skip_after]
      User.destroy(@user.id)
      Post.destroy(@post.id)
    end
  end
  #
  it 'creates a comment on post' do
    visit post_path(@post.id)
    comment_string = "my first comment"
    fill_in("comment_content_#{@post.id}", with: comment_string)
    binding.pry
    
    click_button 'New Comment'

    expect(page).to have_content(comment_string)
    expect(page).to have_css("user-name", @user.username)
  end

end

private

def visit_new_post
  visit '/'
  find_link('New Post').click
end

