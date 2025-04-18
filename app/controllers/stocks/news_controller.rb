# This controller handles requests for stock news.
# It fetches news articles related to a specific stock from the Synth Finance API.
class Stocks::NewsController < ApplicationController
  # GET /stocks/:stock_ticker/news
  # Retrieves and displays news articles for a specific stock.
  #
  # @param stock_ticker [String] The ticker symbol of the stock (passed in the URL)
  # @return [Array] An array of news articles related to the specified stock
  def show
    if params[:stock_ticker].include?(":")
      symbol, mic_code = params[:stock_ticker].split(":")
      @stock = Stock.find_by(symbol:, mic_code:)
    else
      @stock = Stock.find_by(symbol: params[:stock_ticker], country_code: "US")
    end

    if cached = Rails.cache.read("stock_news/v2/#{@stock.symbol}:#{@stock.mic_code}")
      @news = cached
      respond_to do |format|
        format.html { render :show }
        format.json { render json: @news }
      end
      return
    end

    @news = Rails.cache.fetch("stock_news/v2/#{@stock.symbol}:#{@stock.mic_code}", expires_in: 12.hours) do
      headers = {
        "Content-Type" => "application/json",
        "Authorization" => "Bearer #{ENV['SYNTH_API_KEY']}",
        "X-Source" => "maybe_marketing",
        "X-Source-Type" => "api"
      }

      response = Faraday.get("https://api.synthfinance.com/tickers/#{@stock.symbol}/news?mic_code=#{@stock.mic_code}", nil, headers)

      if response.success?
        JSON.parse(response.body)["data"]
      else
        []
      end
    end

    respond_to do |format|
      format.html { render :show }
      format.json { render json: @news }
    end
  end
end
