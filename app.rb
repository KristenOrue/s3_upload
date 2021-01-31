require 'aws-sdk'
#assume the role

role_credentials = Aws::AssumeRoleCredentials.new(
  client: Aws::STS::Client.new,
  role_arn: "arn:aws:iam::589772831734:role/role4dan",
  role_session_name: "s3-upload-session"
)

s3 = Aws::S3::Client.new(credentials: role_credentials)

#list s3 Objects
# test should fail until out role is assumed
pp s3.list_buckets

#upload a file