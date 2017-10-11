class Ability
  include CanCan::Ability

  def initialize(user)
    can :read, Board
    can :manage, Ticket
  end
end
