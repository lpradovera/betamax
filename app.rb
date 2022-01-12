require 'dotenv/load'
require 'sinatra'
require 'faraday'
require "sinatra/reloader" if development?

set :bind, '0.0.0.0'

# Utility method to perform HTTP requests against the SW Video API
def api_request(payload, endpoint, method = :post)
  conn = Faraday.new(url: "https://#{ENV['SIGNALWIRE_SPACE']}/api/video/#{endpoint}")
  conn.basic_auth(ENV['SIGNALWIRE_PROJECT_KEY'], ENV['SIGNALWIRE_TOKEN'])

  if method == :post
    response = conn.post() do |req|
      req.headers['Content-Type'] = 'application/json'
      req.body = payload.to_json
    end
  else
    response = conn.get() do |req|
      req.headers['Content-Type'] = 'application/json'
    end
  end

  JSON.parse(response.body)
end

# Request a token with simple capabilities
def request_token(room, user = nil)
  payload = {
    room_name: room,
    user_name: user.nil? ? "user#{rand(1000)}" : user,
    permissions: [
      'room.self.audio_mute',
      'room.self.audio_unmute',
      'room.self.video_mute',
      'room.self.video_unmute',
      'room.self.deaf',
      'room.self.undeaf',
      'room.self.set_input_volume',
      'room.self.set_output_volume',
      'room.self.set_input_sensitivity',
      'room.list_available_layouts',
      'room.set_layout',
      'room.member.video_mute',
      'room.member.audio_mute',
      'room.member.remove',
      'room.recording',
      'room.playback'
    ]
  }
  result = api_request(payload, 'room_tokens')
  result['token']
end

# Create a room to join
def create_room(room)
  payload = {
    name: room,
    display_name: room,
    max_participants: 5,
    delete_on_end: false
  }
  api_request(payload, 'rooms')
end

get '/' do
  @room = params[:room] || "room_#{rand(1000)}"
  @user = params[:user] || "user_#{rand(1000)}"

  @token = request_token(@room, @user)

  rooms_recs = api_request({}, 'room_recordings', :get)
  @recs = rooms_recs['data']
  erb :index
end

get '/list' do
  rooms = api_request({}, 'room_recordings', :get)
  content_type :json
  rooms['data'].to_json
end