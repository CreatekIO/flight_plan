class Ability
  include CanCan::Ability

  def initialize(user)
    can :manage, Board
    can :manage, Ticket
    can :manage, BoardTicket
    can :manage, Swimlane
    can :manage, User
  end
end
