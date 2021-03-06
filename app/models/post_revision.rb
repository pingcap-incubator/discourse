# frozen_string_literal: true

require_dependency "discourse_diff"

class PostRevision < ActiveRecord::Base
  belongs_to :post
  belongs_to :user

  serialize :modifications, Hash

  after_create :create_notification

  def self.ensure_consistency!
    # 1 - fix the numbers
    DB.exec <<-SQL
      UPDATE post_revisions
        JOIN (
              SELECT id, @row_number:=CASE WHEN @post_id=post_id THEN @row_number+1 ELSE 1 END AS `rank`,
                     @post_id:=post_id 
              FROM post_revisions, (SELECT @row_number:=0,@post_id:='') AS t 
              ORDER BY  post_id, number, created_at, updated_at
             ) AS pr ON post_revisions.id = pr.id AND post_revisions.number <> pr.rank
         SET number = pr.rank + 1
    SQL

    # 2 - fix the versions on the posts
    DB.exec <<-SQL
      UPDATE posts
         SET version = 1 + (SELECT COUNT(*) FROM post_revisions WHERE post_id = posts.id),
             public_version = 1 + (SELECT COUNT(*) FROM post_revisions pr WHERE post_id = posts.id AND pr.hidden = false)
       WHERE version <> 1 + (SELECT COUNT(*) FROM post_revisions WHERE post_id = posts.id)
          OR public_version <> 1 + (SELECT COUNT(*) FROM post_revisions pr WHERE post_id = posts.id AND pr.hidden = false)
    SQL
  end

  def hide!
    update_column(:hidden, true)
  end

  def show!
    update_column(:hidden, false)
  end

  def create_notification
    PostActionNotifier.after_create_post_revision(self)
  end

end

# == Schema Information
#
# Table name: post_revisions
#
#  id            :bigint           not null, primary key
#  user_id       :integer
#  post_id       :integer
#  modifications :text(65535)
#  number        :integer
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  hidden        :boolean          default(FALSE), not null
#
# Indexes
#
#  index_post_revisions_on_post_id             (post_id)
#  index_post_revisions_on_post_id_and_number  (post_id,number)
#
