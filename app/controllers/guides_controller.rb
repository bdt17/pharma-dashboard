# Public, search-indexable DSCSA guides (see Guide). No sign-in.
class GuidesController < ApplicationController
  def index
    @guides = Guide::ALL
  end

  def show
    @guide = Guide.find(params[:slug]) or raise ActionController::RoutingError, "Not Found"
    render @guide.slug
  end
end
