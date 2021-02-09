class Ability
  include CanCan::Ability

  def initialize(user)
    return unless user.present?

    can :manage, Board
    can :manage, BoardTicket

    return if user == :api_user

    can :manage, Repo
    can :manage, Ticket
    can :manage, Swimlane
    can :manage, User

    can :manage, :kpis do
      Flipper.enabled?(:kpis, user)
    end

    can %i[opt_in opt_out], Flipper::Feature, name: %i[v2_ui]
  end
end
