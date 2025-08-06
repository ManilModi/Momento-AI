import boto3
import os
from dotenv import load_dotenv
load_dotenv()

ACCESS_KEY = os.getenv("ACCESS_KEY")
SECRET_KEY = os.getenv("SECRET_KEY")
BUCKET_NAME = os.getenv("BUCKET_NAME")
REGION = os.getenv("REGION")

# Initialize S3 client
s3 = boto3.client(
    's3',
    aws_access_key_id=ACCESS_KEY,
    aws_secret_access_key=SECRET_KEY,
    region_name=REGION
)

# List objects in the bucket
response = s3.list_objects_v2(Bucket=BUCKET_NAME)
for obj in response.get('Contents', []):
    print(obj['Key'])

# Example: download a file
# s3.download_file(BUCKET_NAME, 'photo1.jpg', 'photo1.jpg')

