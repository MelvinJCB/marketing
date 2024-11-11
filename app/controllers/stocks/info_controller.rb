# This controller handles requests for stock information.
# It fetches stock data from the Synth Finance API for a given stock ticker.
class Stocks::InfoController < ApplicationController
  # GET /stocks/:stock_ticker/info
  # Retrieves and displays information for a specific stock.
  #
  # @param stock_ticker [String] The ticker symbol of the stock (passed in the URL)
  # @return [Object] Sets @stock and @stock_info instance variables for use in the view
  def show
    @stock = Stock.find_by(symbol: params[:stock_ticker])

    @stock_info = Rails.cache.fetch("stock_info/v1/#{@stock.symbol}", expires_in: 24.hours) do
      headers = {
        "Content-Type" => "application/json",
        "Authorization" => "Bearer #{ENV['SYNTH_API_KEY']}",
        "X-Source" => "maybe_marketing",
        "X-Source-Type" => "api"
      }

      response = Faraday.get("https://api.synthfinance.com/tickers/#{@stock.symbol}", nil, headers)
      JSON.parse(response.body)["data"]
    end
  end
end
