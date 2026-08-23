class HomeController < ApplicationController
  before_action :authenticate_user!, only: [
    :gps
  ]

  # Previously showed the same "Sign in" button regardless of auth state.
  # A signed-in user clicking it would hit Devise's require_no_authentication
  # guard (it won't show the sign-in form to someone already signed in) and
  # get bounced right back here -- looking exactly like a broken login loop,
  # even though the session was valid the whole time. Send them straight to
  # the dashboard instead.
  #
  # This used to `render html: "...".html_safe` inline, which skips
  # layouts/application.html.erb entirely -- so the homepage (the one page
  # every anonymous visitor and prospect actually lands on) shipped with no
  # Tailwind, no importmap/Stimulus, no nav, and critically no "Sign up"
  # link, only "Sign in". Rendering the real template instead fixes all of
  # that for free.
  def index
    redirect_to dashboard_path if user_signed_in?
  end

  def login
    redirect_to new_user_session_path
  end

  # Real fleet positions for the signed-in user's organization, scoped the
  # same way the API is (VehiclePolicy::Scope) -- this used to render a
  # hardcoded JSON stub claiming "vehicles: 0" regardless of what was
  # actually in the database.
  def gps
    @vehicles = policy_scope(Vehicle).order(:name)
  end

  def health
    render plain: "ok"
  end

  def signup
    redirect_to new_user_registration_path
  end

  def landing
    redirect_to root_path
  end
end
