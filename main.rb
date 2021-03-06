require 'sinatra'
require 'sinatra/reloader'
require 'pry'
require 'active_record'
require 'pg'
require 'time_difference'
require_relative 'db_config'
require_relative 'models/task'
require_relative 'models/timer'
require_relative 'models/project'

def timer_currently_running?(task_id)
    return true if (Timer.where(task_id: task_id).where(end_time: nil)).length != 0
    false
end

def get_current_timer(task_id)
  Timer.where(task_id: task_id).where(end_time: nil)[0][:start_time]
end

def time_conversion(minutes)
  hours = minutes / 60
  rest = minutes % 60
  "#{hours}:#{rest}" 
end

get '/' do
  erb :index
end

get '/tasks' do
  @tasks = Task.all
  @tasks.order(created_at: :desc)
  @timers = Timer.all
  @current_time = Time.new
  erb :tasks
end

post '/tasks' do
  @task = Task.new
  @task.task_name = params[:task_name]
  @task.created_at = Time.new
  @task.save
  redirect '/tasks'
end

delete '/tasks/:id' do
  @task = Task.find(params[:id])
  @task.destroy
  redirect '/tasks'
end


put '/task/:id/complete' do
  @task = Task.find(params[:id])
  @task.completed = true
  @task.save
  @timer = Timer.where(task_id: @task[:id]).where(end_time: nil)
  if @timer.length > 0
    @timer[0].end_time = Time.new
    @timer[0].total_time = (TimeDifference.between(@timer[0].start_time, @timer[0].end_time).in_minutes).round
    @timer[0].save
  end
  redirect '/tasks'
end

put '/task/:id/uncomplete' do
  @task = Task.find(params[:id])
  @task.completed = false
  @task.save
  redirect '/tasks'
end

post '/:id/start-timer' do
  # if statement here
  @task = Task.find(params[:id])
  @timer = Timer.new
  @timer.start_time = Time.new
  @timer.task_id = params[:id]
  @timer.save
  redirect '/tasks'
end

put '/:id/stop-timer' do
  @timer = Timer.where(task_id: params[:id]).where(end_time: nil)
  @timer[0].end_time = Time.new
  @timer[0].total_time = (TimeDifference.between(@timer[0].start_time, @timer[0].end_time).in_minutes).round
  @timer[0].save
  redirect '/tasks'
end

get '/projects' do
  @project = Project.all
  @tasks = Task.all
  # @tasks = Project.join(:tasks)
  erb :projects
end