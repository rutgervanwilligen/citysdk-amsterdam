#test recurring events
require 'ice_cube'
require 'date'
require 'time'

include IceCube

puts 'geelvinck'

inrijden_dagelijks = Schedule.new(start = Time.parse("2013-01-01 07:00"), :end_time => Time.parse("2013-01-01 02:00")) 
inrijden_dagelijks.add_recurrence_rule(Rule.weekly.day(1,2,3,4))

inrijden_vrijdag = Schedule.new(start = Time.parse("2013-01-01 07:00"), :end_time => Time.parse("2013-01-01 06:00"))
inrijden_vrijdag.add_recurrence_rule(Rule.weekly.day(5))

inrijden_zaterdag = Schedule.new(start = Time.parse("2013-01-01 09:00"), :end_time => Time.parse("2013-01-01 06:00"))
inrijden_zaterdag.add_recurrence_rule(Rule.weekly.day(6))

inrijden_zondag = Schedule.new(start = Time.parse("2013-01-01 09:30"), :end_time => Time.parse("2013-01-01 02:00"))
inrijden_zondag.add_recurrence_rule(Rule.weekly.day(0))

rules = [inrijden_dagelijks, inrijden_vrijdag, inrijden_zaterdag, inrijden_zondag]

rules.each do |rule|
	puts rule.to_ical
end

rules.each do |rule|
	puts "#{rule.start_time.hour}-#{rule.end_time.hour} #{rule.to_s}"
end

puts 'waterlooplein'
inrijden_dagelijks = Schedule.new(start = Time.parse("2013-01-01 07:00"), :end_time => Time.parse("2013-01-01 02:00"))
inrijden_dagelijks.add_recurrence_rule(Rule.daily)

puts inrijden_dagelijks.to_ical
puts "#{inrijden_dagelijks.start_time.hour}-#{inrijden_dagelijks.end_time.hour} #{inrijden_dagelijks.to_s}"
