class K12Controller < ApplicationController
  protect_from_forgery with: :null_session

  FIELDS = ['id', 'last_name', 'first_name', 'grade']

  def index
    dynamodb = Aws::DynamoDB::Client.new
    k12 = dynamodb.scan(table_name: 'k12').items
    render json: { k12: k12 }
  end

=begin
  def create
    dynamodb = Aws::DynamoDB::Client.new
    k12 = params[:k12]
    if k12
      if k12[:id]
        attributes = Hash.new
        k12.each do |key, value|
          unless key == 'id'
            attributes[key] = { value: value, action: 'PUT' }
          end
        end
        dynamodb.put_item(table_name: 'k12',
                          key: { id: k12[:id] },
                          attribute_updates: attributes,
                          condition_expression: "attribute_not_exists(id),
                          return_values: "ALL_NEW")
      else
        return head :bad_request
      end
    else
      return head :bad_request
    end
    render json: k12
  end
=end

  def create
    dynamodb = Aws::DynamoDB::Client.new
    k12 = params[:k12]
    if k12 && k12[:id]
      begin
        dynamodb.put_item(table_name: 'k12',
                          item: k12,
                          condition_expression: 'attribute_not_exists(id)')
        k12 = dynamodb.get_item(table_name: 'k12',
                                key: {'id': k12[:id]}).item
      rescue Exception
        return head :bad_request
      end
    else
      return head :bad_request
    end
    render json: k12
  end

  def read
    dynamodb = Aws::DynamoDB::Client.new
    begin
      id = Integer(params[:id])
      k12 = dynamodb.get_item(table_name: 'k12',
                        key: {'id': id}).item
      unless k12
        return head :not_found
      end
    rescue ArgumentError
      return head :bad_request
    rescue Exception
      return head :not_found
    end
    render json: k12
  end

  def update
    dynamodb = Aws::DynamoDB::Client.new
    k12 = params[:k12]
    if k12
      begin
        id = Integer(params[:id])
        attributes = Hash.new
        k12.each do |key, value|
          unless key == 'id'
            attributes[key] = {value: value, action: 'PUT'}
          end
        end
        k12 = dynamodb.update_item(table_name: 'k12',
                                  key: {'id': id},
                                  attribute_updates: attributes,
                                  expected: {'id': {comparison_operator: 'NOT_NULL'}},
                                  return_values: 'ALL_NEW').attributes
      rescue Aws::DynamoDB::Errors::ConditionalCheckFailedException
        return head :not_found
      rescue Exception
        return head :bad_request
      end
    else
      return head :bad_request
    end
    render json: k12
  end

  def delete
    dynamodb = Aws::DynamoDB::Client.new
    begin
      id = Integer(params[:id])
      k12 = dynamodb.delete_item(table_name: 'k12',
                              key: {'id': id},
                              condition_expression: 'attribute_exists(id)',
                              return_values: 'ALL_OLD').attributes
    rescue Aws::DynamoDB::Errors::ConditionalCheckFailedException
      return head :not_found
    rescue Exception => e
      return head :bad_request
    end
    render json: k12
  end
end
