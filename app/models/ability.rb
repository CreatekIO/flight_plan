class Ability
  include CanCan::Ability

  def initialize(user)
    can :read, Board
    can :read, Ticket
  end
end
