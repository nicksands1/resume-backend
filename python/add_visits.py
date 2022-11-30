import json
import boto3

dynamodb = boto3.resource('dynamodb')
table = dynamodb.Table('visit_table')
def lambda_handler(event, context):
    response = table.get_item(Key={
            'record_id':'0'
    })
    visitor_count = response['Item']['visitor_count']
    visitor_count = visitor_count + 1
    print(visitor_count)
    response = table.put_item(Item={
            'record_id':'0',
            'visitor_count': visitor_count
    }
    return "Records added successfully!"
    )
    
