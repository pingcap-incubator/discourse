# frozen_string_literal: true

class BadgeGrouping < ActiveRecord::Base

  GettingStarted = 1
  Community = 2
  Posting = 3
  TrustLevel = 4
  Other = 5

  has_many :badges

  def system?
    id && id <= 5
  end

  def default_position=(pos)
    self.position ||= pos
  end
end

# == Schema Information
#
# Table name: badge_groupings
#
#  id          :bigint           not null, primary key
#  name        :string(255)      not null
#  description :text(65535)
#  position    :integer          not null
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#
