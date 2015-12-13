require 'aws-sdk'
require 'net/http'
require 'json'

#Aws.config.update({
#  region: 'us-west-2',
#  credentials: Aws::Credentials.new('AKIAIXWVWSVGRVRUPEJQ', 'NFbMlcHWVjeBHs6Wmq7QuHLx2aVShrQqSFvgAxNE')
#})

AWS.config(access_key_id: 'AKIAIXWVWSVGRVRUPEJQ', secret_access_key: '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', region: 'us-east-1')

class GatewayController < ApplicationController
	def index
		sqs = AWS::SQS.new

		puts "Getting list of all queues ..."
		url = 'https://sqs.us-east-1.amazonaws.com/594922646820'
		puts sqs.queues.collect(&:url)

		queue_name = 'K12'
		domain = 'http://104.131.75.130/k12'

		q = nil
		begin
		  # Creates new queue or gets existing queue
		  q = sqs.queues.create queue_name
		rescue AWS::SQS::Errors::InvalidParameterValue => e
		  puts "Invalid queue name '#{queue_name}'. "+e.message
		  exit 1
		end

		@result ||= []
		while true
		# Now get  the first message from queue
		q.poll(:idle_timeout => 5) do |msg|
		  #puts "Retrieved the message '#{msg.body}'"
		  user_req = JSON.parse(msg.body)
		  puts user_req['body']
		  real_uri = domain + user_req['header']['url']
		  uri = URI(real_uri)
		  if user_req['header']['op'] == 'GET'
			res = Net::HTTP.get_response(uri) # => String
		  else
		  	case user_req['header']['op']
		  	when 'POST'
		  	  req = Net::HTTP::Post.new(uri, initheader = {'Content-Type' =>'application/json'})
		  	when 'PUT'
		  	  req = Net::HTTP::Put.new(uri, initheader = {'Content-Type' =>'application/json'})
		  	when 'DELETE'
		  	  req = Net::HTTP::Delete.new(uri, initheader = {'Content-Type' =>'application/json'})
		  	end
		    req.body = user_req['body'].to_json
		    res = Net::HTTP.start(uri.hostname, uri.port) do |http|
		  	  http.request(req)
		    end
		  end

		  # send response back to user's queue

			rq = nil
			begin
			  # Creates new queue or gets existing queue
			  rq = sqs.queues.create user_req['header']['response_queue']
			rescue AWS::SQS::Errors::InvalidParameterValue => e
			  puts "Invalid queue name '#{queue_name}'. "+e.message
			  exit 1
			end
			message = %Q[{
				"cid": #{user_req['header']['cid']},
				"body": #{res.body}
			}]

			# Send message to queue
			#puts "Sending message '#{message}' to queue ..."
			m = rq.send_message message
			puts "A message is created on queue with id '#{m.id}'"

		  @result.push(res.body)

		end
		end

	render json: @result

	end




end
