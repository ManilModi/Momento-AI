import boto3
import uuid
from botocore.exceptions import NoCredentialsError
import os
from dotenv import load_dotenv
load_dotenv() 

AWS_REGION = os.getenv("REGION")
S3_BUCKET = os.getenv("BUCKET_NAME")



s3 = boto3.client(
    's3',
    region_name=AWS_REGION,
    aws_access_key_id=os.getenv("ACCESS_KEY"),
    aws_secret_access_key=os.getenv("SECRET_KEY")
)

def upload_image_to_s3(filename: str, content: bytes) -> str:
    try:
        print("🧪 Type of filename:", type(filename))
        print("🧪 Type of content:", type(content))
        print("🧪 Filename:", filename)
        print("🧪 Content is None?", content is None)
        print("🧪 Content length:", len(content) if content else "Empty")

        if not isinstance(filename, str):
            raise TypeError("Expected filename to be a string")

        if not isinstance(content, (bytes, bytearray)):
            raise TypeError("Expected content to be bytes or bytearray")

        s3.put_object(Bucket=S3_BUCKET, Key=filename, Body=content, ContentType='image/jpeg')

        url = f"https://{S3_BUCKET}.s3.{AWS_REGION}.amazonaws.com/{filename}"
        print("✅ Uploaded to S3:", url)
        return url
    except NoCredentialsError:
        raise Exception("AWS credentials not found")
    except Exception as e:
        raise Exception(f"S3 Upload failed: {e}")

