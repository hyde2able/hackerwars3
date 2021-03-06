namespace :event do
    desc "毎分実施。クロールしてトレンドがあれば問題を生成する"
    task create: :environment do
        trend_word = get_a_trend || 'google'

        # trend_wordでTweetを検索し、DBに登録
        # client = get_twitter_client
        # query = trend_word
        # puts query
        # result_tweets = client.search(query, count: 15, locale: "ja", result_type: "recent",  exclude: "retweets")
        # result_tweets.each_with_index do |tw, i|
        #   # puts "#{i}: #{tw.id}: @#{tw.user.screen_name}: #{tw.full_text}"
        #   tweet = Tweet.new({tweet_id: tw.id, name: tw.user.name, screen_name: tw.user.screen_name, full_text: tw.full_text})
        #   tweet.save
        # end

        event = Event.new
        event.trend_word = trend_word
        event.start_time = Time.zone.now
        event.end_time = event.start_time + 3.minutes
        event.save
    end

    desc "答えの集計 #=> イベントのトレンドとその答えにきたユーザ名との相関が一番大きい順にソート"
    task aggregate: :environment do
        Event.where(finished: false).all.each do |event|
            w1 = event.trend_word
            x = []
            event.cards.each do |card|
                association = associate w1, card.name
                if card.followers_count <= 1000
                  association += card.followers_count * rand(10..1000)
                else
                  association += card.followers_count / 10
                end
                x.push([association, card.id])
            end
            x = x.sort_by { |b, _| b }.reverse

            tmp_result = ""
            x.each_with_index do |res, ind|
                if ind == 0
                    tmp_result += "#{ind+1}:#{res[0]}:#{res[1]}"
                else
                    tmp_result += ",#{ind+1}:#{res[0]}:#{res[1]}"
                end  # 順位:相関度:カード番号
            end
            event.result = tmp_result

            if x.present? && x[0].present? && x[0][1].present?
                winner_card_id = x[0][1].to_i
                winner_id = Card.find(winner_card_id).user.id

                # 参加者のスコアを更新
                x.each_with_index do |res, ind|
                    association = res[0].to_i
                    card_id = res[1].to_i
                    card = Card.find_by(id: card_id)
                    user = card.user

                    if ind == 0
                        user.win += 1
                    else
                        user.lose += 1
                        card.user_id = winner_id
                    end
                    score = (x.size - ind) * 15 + (association / 100000)
                    user.score += score
                    user.save
                end

                event.finished = true
                event.save
            end
        end
    end

    private
    # TwitterAPI
    def get_twitter_client
      client = Twitter::REST::Client.new do |config|
        config.consumer_key        = '8XDFefeCi9JKqW0nnJkJxV62c'
        config.consumer_secret     = 'ExyBu6FMWyp49xHwZFqXeUMcepDXND6dKHl16mdKoz2qnqK5Cz'
        config.access_token        = '3976234632-0kxLLEDxJKgDtyVjfVnETNQmjb53Pa4GlG7DUq0'
        config.access_token_secret = 'QQxoHgLhIpDjoo2ntckMR6KiHc9f6WITVtyCjD212rCxQ'
       end
      client
    end

    # トレンドのキーワードを取得
    def get_a_trend
        require "open-uri"
        return get_trends[rand(10)]
    end

    def get_trends
        trends = []
        # 検索結果を開く
        doc = Nokogiri.HTML(open("http://www.google.co.jp/trends/hottrends/atom/hourly"))
        doc.css('a').each do |anchor|
            trends.push(anchor.inner_text)
        end
        return trends
    end

    # w1とw2の関連度を数値で返す
    def associate w1, w2
        require 'nokogiri'
        require 'open-uri'
        require 'cgi'

        key = "#{w1} #{w2}"
        escaped_key = CGI.escape(key)

        doc = Nokogiri.HTML( open("https://www.google.co.jp/search?ie=UTF-8&oe=UTF-8&q=#{escaped_key}") )
        str_of_number = doc.css('#resultStats').text
        number = str_of_number.delete!("約 ").delete!("件").delete!(",")
        return number.to_i
    end
end
