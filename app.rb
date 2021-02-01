require 'aws-sdk'
require 'aws-sdk-s3'

#Command Line argument work
NO_SUCH_BUCKET = "The bucket '%s' does not exist!"

USAGE = <<DOC

Usage: hello-s3 bucket_name [operation] [file_name]

Where:
  bucket_name (required) is the name of the bucket

  operation   is the operation to perform on the bucket:
              create  - creates a new bucket
              upload  - uploads a file to the bucket
              list    - (default) lists up to 50 bucket items

  file_name   is the name of the file to upload,
              required when operation is 'upload'

DOC

#Sets the name of the bucket on which the operations are performed
bucket_name = nil

if ARGV.length > 0
  bucket_name = ARGV[0]
else
  puts USAGE
  exit 1
end

#The operation to be performed on the bucket
operation = ARGV[1] if (ARGV.length > 1)

#The file name to use alongside 'upload'
file = nil
file = ARGV[2] if (ARGV.length > 2)

#assume the role
role_credentials = Aws::AssumeRoleCredentials.new(
  client: Aws::STS::Client.new,
  role_arn: "arn:aws:iam::589772831734:role/role4dan",
  role_session_name: "s3-upload-session"
)

#Get the Amazon client role credentials
s3_client = Aws::S3::Client.new(credentials: role_credentials)

#Different the operation name matches ARGV[1]
case operation
when 'upload'
  if file == nil
    puts "You must enter a file name to upload to S3!"
    exit
  else 
    file_name= File.basename file
    # puts "File has been stored: '%s'" %file_name
    # puts "Bucket has been stored: '%s'" %bucket_name
    s3_client.put_object( bucket: bucket_name, key: file_name)
    puts "File '#{file_name}' uploaded to bucket '#{bucket_name}'."
  end
else
  puts "Unknown operation: '%s'!" % operation
  puts USAGE
end