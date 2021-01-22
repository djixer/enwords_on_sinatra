#!/usr/bin/ruby

require 'rubygems'
require 'sinatra'
require 'sinatra/reloader'
require 'sinatra/activerecord'

# set :port, 8090
set :bind, '0.0.0.0'
set :database, "sqlite3:enwords.db"

class Word < ActiveRecord::Base
	validates :eng_word, :presence => true, :uniqueness => true
end

class Test < ActiveRecord::Base
end

before do
	@words = Word.all
	@tests = Test.all
end

get '/' do
  erb :index
end

get '/test' do
	#Выберем все слова, которые не считаются выученными (менее 10 правильных ответов) и из них для теста возьмём случайные 10 слов:
  	array_10_words_for_test = Word.where('right_answers < 10').select(:id, :eng_word, :rus_word, :transcription).sample(10)
  	i = 0
  	@eng_word = []
  	@rus_word = []
  	@id_slova = []
	@transcription = []
  	array_10_words_for_test.each do |couple|
  		@eng_word[i] = couple.eng_word
  		@rus_word[i] = couple.rus_word
  		@id_slova[i] = couple.id
		@transcription[i] = couple.transcription
  		i += 1
  	end
	erb :test
end

post '/test' do
	# Проверяем ответы, полученные из формы теста:
	@id_slova = []
	@eng_original = []
	@user_answer = []
	@right_answer = []
	test_word = []
	@ans = []
	
	(0..9).each do |i|
		@id_slova[i] = params[:id_slova][i]
		@eng_original[i] = params[:eng_original][i]
		@user_answer[i] = params[:answer][i].split(', ').sort
		@right_answer[i] = params[:right_answer][i].split(', ').sort

		test_word[i] = Word.where("id = #{@id_slova[i]}").select(:id)
    # Увеличиваем счётчики слов правильных/неправильных ответов:
    if @user_answer[i] == @right_answer[i]
			Word.increment_counter(:right_answers, test_word[i])
			@ans[i] = 1
		else
			Word.increment_counter(:wrong_answers, test_word[i])
			@ans[i] = 0
		end
	end

 # Считаем результат и записываем его в базу:
  @result_right_answers = @ans.sum
	save_test_result = Test.new
	save_test_result.points = @result_right_answers
	save_test_result.save

erb :result
end

get '/stats' do
	@learned_words = Word.where('right_answers >= 10')
  erb "Hello!"
  erb :stats
end

get '/words' do
  erb :words
end

get '/add-new-words' do
	erb :add_new_words
end

post '/add-new-words' do
  # Добавление новых слов для тестирований в базу:
	new_word = Word.new params[:word]
	if new_word.save
		erb "<h3>Спасибо, вы записали новое слово в базу!</h3>"
		erb :add_new_words
	else
		@error = new_word.errors.full_messages.first
		erb :add_new_words
	end
end

get '/reset-statistics' do
	erb :reset_statistics
end

post '/reset-statistics' do
  # Сброс статистистики:
	decision = params[:word_for_reset]
	if decision == 'all'
		Word.update_all(:right_answers => 0, :wrong_answers => 0)
	else
		Word.update(decision, :right_answers => 0, :wrong_answers => 0)
	end
	erb :index
end
