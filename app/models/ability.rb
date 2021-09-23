class Ability
  include CanCan::Ability

  SELF_SERVE_FEATURES = FEATURES.flat_map do |feature|
    [feature.name.to_sym, name.to_s]
  end.freeze

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

    can %i[opt_in opt_out], Flipper::Feature, name: SELF_SERVE_FEATURES
  end
end
