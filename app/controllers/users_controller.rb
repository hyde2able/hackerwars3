class UsersController < ApplicationController
  before_action :authenticate_user!, only: [:show, :get_cards]
  def index
  	@users = User.all
  end

  def show
  	unless current_user.cards.present?
  		redirect_to get_cards_user_url(current_user.id), notice: '好きなアカウントを5つ選択してください。'
  		return
  	end
  	@user = current_user || User.find_by(id: params[:id])
  	@cards = @user.cards
  	gon.event_id = Event.last.try(:id) || 0
  	gon.tweet_id = Tweet.last.try(:id) || 0

  	@recent_events = Event.order('id desc').limit(4)
  	#@trend = google_trend('google','apple','yahoo','uber')
  	#@cards = current_user.cards.pluck(:id, :name, :screen_name, :tweets_count, :followers_count, :profile_image_url)
  end

  def get_cards
  	gon.user_id = current_user.id
  	@cards = Card.order("RANDOM()").limit(100)
  end

  def post_cards
  	require 'csv'
  	@user = User.find(params[:id])

    Card.transaction do
      params[:ids].parse_csv.each do |card_id|
        card = Card.find(card_id.to_i)
        card.update(user_id: @user.id)
        card.save
      end
    end
  	@user.score += 10
  	@user.save
  	render nothing: true
  end

  private
  require "nokogiri"
	require "open-uri"
	require "cgi"
  	# w1, w2, w3, w4に関するトレンドの推移
  	def google_trend(w1, w2, w3, w4)
		# 検索結果を開く
  		doc = Nokogiri.HTML(open("http://www.google.com/trends/fetchComponent?hl=ja-JP&q=#{w1},#{w2},#{w3},#{w4}&cid=TIMESERIES_GRAPH_0&export=5&w=250&h=300"))
  		return doc
  	end
end
