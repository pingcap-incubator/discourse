# frozen_string_literal: true

class IncomingEmail < ActiveRecord::Base
  belongs_to :user
  belongs_to :topic
  belongs_to :post

  scope :errored,  -> { where("NOT is_bounce AND error IS NOT NULL") }

  scope :addressed_to, -> (email) do
    where(<<~SQL, email: "%#{email}%".downcase)
      LOWER(incoming_emails.to_addresses) LIKE :email OR
      LOWER(incoming_emails.cc_addresses) LIKE :email
    SQL
  end

  scope :addressed_to_user, ->(user) do
    where(<<~SQL, user_id: user.id)
      EXISTS(
          SELECT 1
          FROM user_emails
          WHERE user_emails.user_id = :user_id AND
                (LOWER(incoming_emails.to_addresses) LIKE CONCAT('%', LOWER(user_emails.email), '%') OR
                 LOWER(incoming_emails.cc_addresses) LIKE CONCAT('%', LOWER(user_emails.email), '%'))
      )
    SQL
  end
end

# == Schema Information
#
# Table name: incoming_emails
#
#  id                :bigint           not null, primary key
#  user_id           :integer
#  topic_id          :integer
#  post_id           :integer
#  raw               :text(65535)
#  error             :text(65535)
#  message_id        :text(65535)
#  from_address      :text(65535)
#  to_addresses      :text(65535)
#  cc_addresses      :text(65535)
#  subject           :text(65535)
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  rejection_message :text(65535)
#  is_auto_generated :boolean          default(FALSE)
#  is_bounce         :boolean          default(FALSE), not null
#
# Indexes
#
#  index_incoming_emails_on_created_at  (created_at)
#  index_incoming_emails_on_error       (error)
#  index_incoming_emails_on_message_id  (message_id)
#  index_incoming_emails_on_post_id     (post_id)
#  index_incoming_emails_on_user_id     (user_id)
#
