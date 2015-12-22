class K12Controller < ApplicationController
  protect_from_forgery with: :null_session

  FIELDS = ['id', 'last_name', 'first_name', 'grade']

  def index
    dynamodb = Aws::DynamoDB::Client.new
    k12 = dynamodb.scan(table_name: 'k12').items
    render json: {k12: k12}
  end

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
    render json: {k12: k12}
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
    render json: {k12: k12}
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
    render json: {k12: k12}
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
    rescue Exception
      return head :bad_request
    end
    render json: {k12: k12}
  end

  def create_field
    dynamodb = Aws::DynamoDB::Client.new
    begin
      id = Integer(params[:id])
      k12 = params[:k12]
      field = params[:field]
      if k12 && k12[field]
        value = k12[field]
        k12 = dynamodb.update_item(table_name: 'k12',
                                   key: {'id': id},
                                   attribute_updates: {field => {value: value, action: 'PUT'}},
                                   expected: {'id' => {comparison_operator: 'NOT_NULL'},
                                              field => {comparison_operator: 'NULL'}},
                                   return_values: 'ALL_NEW').attributes
      else
        return head :bad_request
      end
    rescue Exception
      return head :bad_request
    end
    render json: {k12: k12}
  end

  def read_field
    dynamodb = Aws::DynamoDB::Client.new
    begin
      id = Integer(params[:id])
      field = params[:field]
      k12 = dynamodb.get_item(table_name: 'k12',
                              key: {'id': id},
                              attributes_to_get: [field]).item
      unless k12 && k12.length != 0
        return head :not_found
      end
    rescue Exception
      return head :bad_request
    end
    render json: {k12: k12}
  end

  def update_field
    dynamodb = Aws::DynamoDB::Client.new
    begin
      id = Integer(params[:id])
      k12 = params[:k12]
      field = params[:field]
      if k12 && k12[field]
        value = k12[field]
        k12 = dynamodb.update_item(table_name: 'k12',
                                   key: {'id': id},
                                   attribute_updates: {field => {value: value, action: 'PUT'}},
                                   expected: {'id' => {comparison_operator: 'NOT_NULL'},
                                              field => {comparison_operator: 'NOT_NULL'}},
                                   return_values: 'ALL_NEW').attributes
      else
        return head :bad_request
      end
    rescue Aws::DynamoDB::Errors::ConditionalCheckFailedException
      return head :not_found
    rescue Exception
      return head :bad_request
    end
    render json: {k12: k12}
  end

  def delete_field
    dynamodb = Aws::DynamoDB::Client.new
    begin
      id = Integer(params[:id])
      field = params[:field]
      k12 = dynamodb.update_item(table_name: 'k12',
                                 key: {'id': id},
                                 attribute_updates: {field => {action: 'DELETE'}},
                                 expected: {'id' => {comparison_operator: 'NOT_NULL'},
                                            field => {comparison_operator: 'NOT_NULL'}},
                                 return_values: 'ALL_NEW').attributes
    rescue Aws::DynamoDB::Errors::ConditionalCheckFailedException
      return head :not_found
    rescue Exception => e
      return render json: e.message
    end
    render json: {k12: k12}
  end
end
