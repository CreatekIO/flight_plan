class Ability
  include CanCan::Ability

  def initialize(user)
    can :manage, Board
    can :manage, Repo
    can :manage, Ticket
    can :manage, BoardTicket
    can :manage, Swimlane
    can :manage, User

    can :manage, :kpis do
      Flipper.enabled?(:kpis, user)
    end
  end
end
