# frozen_string_literal: true

class Permalink < ActiveRecord::Base
  belongs_to :topic
  belongs_to :post
  belongs_to :category

  before_validation :normalize_url

  class Normalizer
    attr_reader :source

    def initialize(source)
      @source = source
      if source.present?
        @rules = source.split("|").map do |rule|
          parse_rule(rule)
        end.compact
      end
    end

    def parse_rule(rule)
      return unless rule =~ /\/.*\//

      escaping = false
      regex = +""
      sub = +""
      c = 0

      rule.chars.each do |l|
        c += 1 if !escaping && l == "/"
        escaping = l == "\\"

        if c > 1
          sub << l
        else
          regex << l
        end
      end

      if regex.length > 1
        [Regexp.new(regex[1..-1]), sub[1..-1] || ""]
      end

    end

    def normalize(url)
      return url unless @rules
      @rules.each do |(regex, sub)|
        url = url.sub(regex, sub)
      end

      url
    end

  end

  def self.normalize_url(url)
    if url
      url = url.strip
      url = url[1..-1] if url[0, 1] == '/'
    end

    normalizations = SiteSetting.permalink_normalizations

    @normalizer = Normalizer.new(normalizations) unless @normalizer && @normalizer.source == normalizations
    @normalizer.normalize(url)
  end

  def self.find_by_url(url)
    find_by(url: normalize_url(url))
  end

  def normalize_url
    self.url = Permalink.normalize_url(url) if url
  end

  def target_url
    return external_url if external_url
    return "#{Discourse::base_uri}#{post.url}" if post
    return topic.relative_url if topic
    return category.url if category
    nil
  end

  def self.filter_by(url = nil)
    permalinks = Permalink
      .includes(:topic, :post, :category)
      .order('permalinks.created_at desc')

    permalinks.where!('LOWER(url) LIKE :url OR LOWER(external_url) LIKE :url', url: "%#{url}%".downcase) if url.present?
    permalinks.limit!(100)
    permalinks.to_a
  end
end

# == Schema Information
#
# Table name: permalinks
#
#  id           :bigint           not null, primary key
#  url          :text(65535)      not null
#  topic_id     :integer
#  post_id      :integer
#  category_id  :integer
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  external_url :text(65535)
#  md5_url      :string(255)
#
# Indexes
#
#  index_permalinks_on_url  (md5_url) UNIQUE
#
