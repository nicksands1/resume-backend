import json, boto3

dynamodb = boto3.resource('dynamodb')
table = dynamodb.Table('visitors')

def lambda_handler(event, context):
   
    response = table.get_item(
        Key={

            'ID': 'visitors'
        }
    )
            
            
    count = response['Item']['Numbers']
    count = str(int(count) + 1)         
            
            
  
    
    response = table.put_item(
        Item = {
            'ID': 'visitors',
            'Numbers': count
        }
    )
   
           
      
    return {
        'statusCode': 200,
        'body':json.dumps({"visitor":str(count)}),
        'headers': {
        'Access-Control-Allow-Origin': '*',
        'Content-Type': 'application/json',
        'Access-Control-Allow-Headers':'*'
        }
    }
    
