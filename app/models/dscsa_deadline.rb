# The one place the DSCSA small-dispenser exemption date lives. Every page
# and email that talks about the deadline asks DscsaDeadline.passed? and
# switches tense on its own the day after -- "ends November 27" would be
# false on November 28, and nobody should have to remember to edit a dozen
# templates that morning. Judged in US Eastern time: the audience is US
# pharmacies, and UTC would flip the copy on the evening of the 27th.
module DscsaDeadline
  DATE = Date.new(2026, 11, 27)
  ZONE = "Eastern Time (US & Canada)".freeze

  def self.today
    Time.find_zone!(ZONE).today
  end

  # True from November 28 on; the 27th itself is still "ends today".
  def self.passed?(on: today)
    on > DATE
  end

  def self.days_left(on: today)
    [ (DATE - on).to_i, 0 ].max
  end

  def self.label
    DATE.strftime("%B %-d, %Y")
  end
end
