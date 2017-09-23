class Ability
  include CanCan::Ability

  def initialize(user)
    can :read, Board
  end
end
