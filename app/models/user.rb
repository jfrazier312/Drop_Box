class User < ApplicationRecord
  acts_as_voter

  PRIVILEGE_OPTIONS = %w(standard admin)

  # enums:
  enum privilege: {
      standard: 0,
      admin: 1
  }, _prefix: :privilege

  # Relationships:
  has_many :posts, dependent: :destroy
  has_many :comments, dependent: :destroy
  has_many :assets, dependent: :destroy
  has_many :shared_assets, dependent: :destroy
  has_many :friends, dependent: :destroy


  # Validations:
  validates :username, presence: true, length: { minimum: 4, maximum: 50 }, uniqueness: { case_sensitive: false }
  validates :email, presence: true, uniqueness: { case_sensitive: false }
  validates :password, presence: true, length: { minimum: 6 }, :if => :password
  validates :privilege, :inclusion => { :in => PRIVILEGE_OPTIONS }

  #####################################################################################################################

  # Instance Methods

  def validate_username
    if User.where(email: username).exists?
      errors.add(:username, :invalid)
    end
  end

  def share_asset_with(asset, user_list)
    SharedAsset.destroy_previous_shares(asset)
    User.transaction do
      raise Exception.new("Must choose a user to share file with") unless user_list && user_list.size > 0
      user_list.each do |username|
        shared_asset = SharedAsset.new(asset_id: asset.id, user_id: User.find_by(username: username).id)
        shared_asset.save!
      end
    end
  end

  # Class Methods
  def self.find_for_database_authentication(warden_conditions)
    conditions = warden_conditions.dup
    if login = conditions.delete(:login)
      where(conditions.to_hash).where(["username = :value OR email = :value", { :value => login.downcase }]).first
      # where(conditions.to_hash).where(["lower(username) = :value OR lower(email) = :value", { :value => login.downcase }]).first
    elsif conditions.has_key?(:username) || conditions.has_key?(:email)
      conditions[:email].downcase! if conditions[:email]
      if conditions[:username].nil?
        where(conditions).first
      else
        where(username: conditions[:username]).first
      end
    end
  end

  def add_friend(user)
    friend = Friend.new(user_1_id: self.id, user_2_id: user.id)
    raise Exception.new('Cannot save friend') unless friend.save!
  end

  # Returns true is either one of these conditionals returns a non empty set
  def is_friends_with?(user)
    !Friend.where(user_1_id: self.id, user_2_id: user.id).empty? || !Friend.where(user_1_id: user.id, user_2_id: self.id).empty?
  end

  def get_all_friends
    Friend.where(user_1_id: self.id) | Friend.where(user_2_id: self.id)
  end

  def check_if_shared_with_me(asset)
    asset = SharedAsset.find_by(user_id: self.id, asset_id: asset.id)
    raise Exception.new('You do not have permission to download this file') if asset.nil?
  end

  def share_with_friends(asset)
    binding.pry
    Asset.transaction do
      friends = self.get_all_friends
      friends.each do |friend|
        SharedAsset.create!(asset_id: asset.id, user_id: friend.id)
      end
    end
  end

  # Returns the hash digest for a given string, used in fixtures for testing
  def User.digest(string)
    cost = ActiveModel::SecurePassword.min_cost ? BCrypt::Engine::MIN_COST :
        BCrypt::Engine.cost
    BCrypt::Password.create(string, cost: cost)
  end


  #Adds functionality to save a securely hashed password_digest attribute to the database
  #Adds a pair of virtual attributes (password and password_confirmation), including presence validations upon object creation and a validation requiring that they match.
  #Adds an authenticate method that returns the user when the password is correct and false otherwise
  has_secure_password


end
