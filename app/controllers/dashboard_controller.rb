class DashboardController < ApplicationController
  def billing
    # Phase 9: Stripe $99/mo per vehicle, $499/mo enterprise
    @plans = [
      { id: 'vehicle', name: '$99/mo per truck', price: 99 },
      { id: 'enterprise', name: '$499/mo multi-tenant', price: 499 },
      { id: 'compliance', name: '$5K one-time setup', price: 5000 }
    ]
    render 'billing', layout: true
  end
end
