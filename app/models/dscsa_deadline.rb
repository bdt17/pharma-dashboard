# The one place the DSCSA small-dispenser exemption date lives. Every page
# and email that talks about the deadline asks DscsaDeadline.passed? and
# switches tense on its own the day after -- "ends November 27" would be
# false on November 28, and nobody should have to remember to edit a dozen
# templates that morning. Judged in US Eastern time: the audience is US
# pharmacies, and UTC would flip the copy on the evening of the 27th.
#
# On 2026-08-06 the FDA extended the exemption a year, from 2026-11-27 to
# 2027-11-27, while it assesses whether small dispensers can feasibly do
# electronic package-level tracing. Qualifying headcount is now measured
# as of 2026-11-27. If the FDA moves it again, change DATE (and
# QUALIFYING_DATE / EXTENDED_ON) here and the copy follows.
module DscsaDeadline
  DATE = Date.new(2027, 11, 27)
  QUALIFYING_DATE = Date.new(2026, 11, 27)
  EXTENDED_ON = Date.new(2026, 8, 6)
  ZONE = "Eastern Time (US & Canada)".freeze

  def self.today
    Time.find_zone!(ZONE).today
  end

  # True from the day after DATE on; DATE itself is still "ends today".
  def self.passed?(on: today)
    on > DATE
  end

  def self.days_left(on: today)
    [ (DATE - on).to_i, 0 ].max
  end

  def self.label
    DATE.strftime("%B %-d, %Y")
  end

  def self.qualifying_label
    QUALIFYING_DATE.strftime("%B %-d, %Y")
  end

  def self.extended_label
    EXTENDED_ON.strftime("%B %-d, %Y")
  end
end
