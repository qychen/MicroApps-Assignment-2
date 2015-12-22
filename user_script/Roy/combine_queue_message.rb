# Copyright 2011 Amazon.com, Inc. or its affiliates. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License"). You
# may not use this file except in compliance with the License. A copy of
# the License is located at
#
#     http://aws.amazon.com/apache2.0/
#
# or in the "license" file accompanying this file. This file is
# distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF
# ANY KIND, either express or implied. See the License for the specific
# language governing permissions and limitations under the License.

# configure the user information
uid = '7'
res_queue = 'response_tom'

gem 'aws-sdk', '< 2'
require 'aws-sdk'

AWS.config(access_key_id: ENV['AWS_ACCESS_KEY_ID'], secret_access_key: ENV['AWS_SECRET_ACCESS_KEY'], region: 'us-east-1')

(queue_name,cid,op,url,body) = ARGV
unless queue_name and cid and body
  puts <<EOS
Usage: #{__FILE__} <QUEUE_NAME> <CID> <OP> <URL> <BODY>
For example: #{__FILE__} myqueue R02 PUT /grade {"first_name": "Roy"}
EOS
  exit 1
end

# Gets an instance of the SQS interface using the default configuration
sqs = AWS::SQS.new

q = nil
begin
  # Creates new queue or gets existing queue
  q = sqs.queues.create queue_name
rescue AWS::SQS::Errors::InvalidParameterValue => e
  puts "Invalid queue name '#{queue_name}'. "+e.message
  exit 1
end
puts body
message = %Q[{
	"header": {
		"op": "#{op}",
		"uid": "#{uid}",
		"response_queue": "#{res_queue}",
		"url": "#{url}",
		"cid": "#{cid}"
	},
	"body": #{body}
}]

# Send message to queue
puts "Sending message '#{message}' to queue ..."
m = q.send_message message
puts "A message is created on queue with id '#{m.id}'"

# Get response message from own queue
begin
  # Creates new queue or gets existing queue
  rq = sqs.queues.create res_queue
rescue AWS::SQS::Errors::InvalidParameterValue => e
  puts "Invalid queue name '#{queue_name}'. "+e.message
  exit 1
end
puts "Retrieving response message ..."
rq.poll(:idle_timeout => 15) do |msg|
  puts "Retrieved the message '#{msg.body}'"
end


