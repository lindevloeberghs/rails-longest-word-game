class LettersNumbersController < ApplicationController

  def game
    @grid = generate_grid(rand(4..10))
    @start_time = Time.now

    @number_of_games_played = session.fetch(:number_of_games_played, 0)
    @average_score          = average_score
  end

  def score
    attempt     = params[:attempt]
    grid        = params[:grid].split(" ")
    start_time  = Time.parse(params[:start_time])

    result        = run_game(attempt, grid, start_time, Time.now)
    @score        = result[:score]
    @time         = result[:time]
    @translation  = result[:translation]
    @message      = result[:message]

    update_metrics
  end

  private

  def update_metrics
    if session[:number_of_games_played]
      session[:number_of_games_played] += 1
    else
      session[:number_of_games_played] = 1
    end

    if session[:total_score]
      session[:total_score] += @score
    else
      session[:total_score] = @score
    end
  end

  def average_score
    if number_of_games_played = session.fetch(:number_of_games_played, 0) > 0
      (session.fetch(:total_score, 0) / session.fetch(:number_of_games_played, 0)).to_f.round(2)
    else
      return 0
    end
  end

  def generate_grid(grid_size)
    Array.new(grid_size) { ('A'..'Z').to_a[rand(26)] }
  end

  def run_game(attempt, grid, start_time, end_time)
    result = { time: end_time - start_time }

    result[:translation] = get_translation(attempt)
    result[:score], result[:message] = score_and_message(
      attempt, result[:translation], grid, result[:time])

    result
  end

  def get_translation(word)
    api_key = "39dd373b-a7ab-4900-b37d-a89209db5a1f"
    begin
      response = open("https://api-platform.systran.net/translation/text/translate?input=#{word}&source=en&target=fr&key=#{api_key}")
      json = JSON.parse(response.read.to_s)
      if json['outputs'] && json['outputs'][0] && json['outputs'][0]['output'] && json['outputs'][0]['output'] != word
        return json['outputs'][0]['output']
      end
    rescue
      if File.read('/usr/share/dict/words').upcase.split("\n").include? word.upcase
        return word
      else
        return nil
      end
    end
  end

  def score_and_message(attempt, translation, grid, time)
    if included?(attempt.upcase, grid)
      if translation
        score = compute_score(attempt, time)
        [score, "well done"]
      else
        [0, "not an english word"]
      end
    else
      [0, "not in the grid"]
    end
  end

  def included?(guess, grid)
    guess.split("").all? { |letter| guess.count(letter) <= grid.count(letter) }
  end

  def compute_score(attempt, time_taken)
    (time_taken > 60.0) ? 0 : attempt.size * (1.0 - time_taken / 60.0)
  end

end
