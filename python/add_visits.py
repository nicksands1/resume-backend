import json
import boto3

client = boto3.client('dynamodb')

def lambda_handler(event, context):

  response = client.update_item(
        TableName='visit_table',
        Key = {
            'visit_count': {'S': 'Quantity'}
        },
        UpdateExpression = 'ADD viewCount :inc',
        ExpressionAttributeValues = {":inc" : {"N": "1"}},
        ReturnValues = 'UPDATED_NEW'
        )

  value = response['Attributes']['viewCount']['N']
    
  return {      
            'statusCode': 200,
            'body': value,
            'headers':{
                'Access-Control-Allow-Origin':'*',
                'Content-Type': 'application/json',
                'Access-Control-Allow-Headers':'*',
                'Access-Control-Allow-Methods':'OPTIONS'
            }
    }
