# frozen_string_literal: true

module Jobs
  class CleanUpUserExportTopics < Jobs::Onceoff
    def execute_onceoff(args)
      translated_keys = I18n.available_locales.map do |l|
        I18n.with_locale(:"#{l}") { I18n.t("system_messages.csv_export_succeeded.subject_template") }
      end.uniq

      slugs = []
      translated_keys.each do |k|
        slugs << "%-#{Slug.for(k.gsub('[%{export_title}]', ''))}"
      end
      # "[%{export_title}] 資料匯出已完成" gets converted to "%-topic", do not match that slug.
      slugs = slugs.reject { |s| s == "%-topic" }
      
      slugs_condition = slugs.map do |slug|
        "slug LIKE '#{EscapeLike.escape_like(slug)}'"
      end.join(" OR ")
      slugs_condition = "1=1" if slugs_condition.blank?
      topics = Topic.with_deleted.where(<<~SQL, UserExport::DESTROY_CREATED_BEFORE)
        #{slugs_condition} AND
        archetype = 'private_message' AND
        subtype = 'system_message' AND
        posts_count = 1 AND
        created_at < ? AND
        user_id = -1
      SQL

      topics.each do |t|
        Topic.transaction do
          t.posts.first.destroy!
          t.destroy!
        end
      end
    end
  end
end
