require 'aws-sdk'
require 'aws-sdk-s3'

# Uploads an object to a bucket in Amazon Simple Storage Service (Amazon S3).
  def run_me
    #assume the role
    role_credentials = Aws::AssumeRoleCredentials.new(
      client: Aws::STS::Client.new,
      role_arn: "arn:aws:iam::589772831734:role/role4dan",
      role_session_name: "s3-upload-session"
    )

    bucket_name = 'meusick-bucket'
    object_key = 'Scream.mp3'
    region = 'us-west-2'
    s3_client = Aws::S3::Client.new(credentials: role_credentials)

    if object_uploaded?(s3_client, bucket_name, object_key)
      puts "Object '#{object_key}' uploaded to bucket '#{bucket_name}'."
    else
      puts "Object '#{object_key}' not uploaded to bucket '#{bucket_name}'."
    end
  end

  def object_uploaded?(s3_client, bucket_name, object_key)
    response = s3_client.put_object(
      bucket: bucket_name,
      key: object_key
    )
    if response.etag
      return true
    else
      return false
    end
  rescue StandardError => e
    puts "Error uploading object: #{e.message}"
    return false
  end

  run_me if $PROGRAM_NAME == __FILE__



#assume the role
# role_credentials = Aws::AssumeRoleCredentials.new(
#   client: Aws::STS::Client.new,
#   role_arn: "arn:aws:iam::589772831734:role/role4dan",
#   role_session_name: "s3-upload-session"
# )

# s3_client = Aws::S3::Client.new(credentials: role_credentials)

# #list s3 Objects
# # test should fail until out role is assumed
# pp s3_client.list_buckets

# #upload a file
# s3_client.put_object()

# # upload file from disk in a single request, may not exceed 5GB
# File.open('/source/file/path', 'rb') do |file|
#   s3_client.put_object(bucket: 'bucket-name', key: 'object-key', body: file)
# end