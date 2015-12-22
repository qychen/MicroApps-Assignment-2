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

# Gets an instance of the SQS interface using the default configuration
sqs = AWS::SQS.new

q = nil
begin
  # Creates new queue or gets existing queue
  q = sqs.queues.create res_queue
rescue AWS::SQS::Errors::InvalidParameterValue => e
  puts "Invalid queue name '#{queue_name}'. "+e.message
  exit 1
end

# Now get  the first message from queue
puts "Retrieving the first message from queue ..."
q.poll(:idle_timeout => 2) do |msg|
  puts "Retrieved the message '#{msg.body}'"
end


