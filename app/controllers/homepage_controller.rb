
  def test_revenue
    render plain: "REVENUE LIVE - Batch #{params[:batch_id] || 1} - FDA Compliance ✓", status: 200
  end
