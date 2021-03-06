# frozen_string_literal: true

class GroupCustomField < ActiveRecord::Base
  belongs_to :group
end

# == Schema Information
#
# Table name: group_custom_fields
#
#  id         :bigint           not null, primary key
#  group_id   :integer          not null
#  name       :string(256)      not null
#  value      :text(65535)
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
# Indexes
#
#  index_group_custom_fields_on_group_id_and_name  (group_id,name)
#
