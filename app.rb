#Reference: https://docs.aws.amazon.com/sdk-for-ruby/v3/developer-guide/hello.html
#Reference: https://docs.aws.amazon.com/sdk-for-ruby/v3/developer-guide/s3-example-upload-bucket-item.html
#Reference: https://docs.aws.amazon.com/sdk-for-ruby/v2/api/Aws/S3/Client.html
#Reference: https://docs.aws.amazon.com/code-samples/latest/catalog/ruby-s3-s3-ruby-example-list-bucket-items.rb.html
#Reference: https://docs.aws.amazon.com/sdk-for-ruby/v3/developer-guide/aws-sdk-ruby-dg.pdf

require 'aws-sdk'
require 'aws-sdk-s3'

#Command Line argument work
NO_SUCH_BUCKET = "The bucket '%s' does not exist!"

USAGE = <<DOC

Usage: ruby app.rb [bucket_name] [operation] [file_name]

Where:

bucket_name (required) is the name of the bucket

operation   is the operation to perform on the bucket:
            upload  - uploads a file to the bucket
            list    - lists bucket objects in a particular s3 bucket
            rename  - Allows you to rename a file in an s3 bucket

file_name   is the name of the file to upload, which can be a File path or a filename
            required when operation is 'upload'

Buckets are listed below: 

DOC


#assume the role
role_credentials = Aws::AssumeRoleCredentials.new(
  client: Aws::STS::Client.new,
  role_arn: "arn:aws:iam::589772831734:role/role4dan",
  role_session_name: "s3-upload-session"
)

#Get the Amazon client role credentials
s3_client = Aws::S3::Client.new(credentials: role_credentials)

#Sets the name of the bucket on which the operations are performed
bucket_name = nil

if ARGV.length > 0
  bucket_name = ARGV[0]
else
  puts USAGE
  pp s3_client.list_buckets
  exit 1
end

#The operation to be performed on the bucket
operation = ARGV[1] if (ARGV.length > 1)

#The file name to use alongside 'upload'
file = nil
file = ARGV[2] if (ARGV.length > 2)

#The new name to use alongside 'rename'
new_name = nil
new_name = ARGV[3] if (ARGV.length > 3)

#Different the operation name matches ARGV[1]
case operation
#To upload a file to the s3 bucket
when 'upload'
  if file == nil
    puts "You must enter a file name to upload to S3!"
    exit
  else
    file_name= File.basename file
    s3_client.put_object( bucket: bucket_name, key: file_name)
    puts "SUCCESS: File '#{file_name}' successfuly uploaded to bucket '#{bucket_name}'."
  end

when 'upload_folder'
  if file == nil
    puts "You must enter a folder path to upload to S3!"
    exit
  else
    folder_name = File.basename(file, ".*")
    is_a_directory= File.directory?(folder_name)
    files_in_directory = Dir.children(folder_name)


    puts folder_name
    puts is_a_directory
    puts files_in_directory

#   s3_client.create_multipart_upload(
#   bucket: "examplebucket", 
#   key: "largeobject", 
# )
  end

#To list the objects inside of a bucket
when 'list'
  if bucket_name == nil
    puts "You must enter a Bucket-name!"
    exit
  else
    puts "Contents of '%s':" % bucket_name
    objects = s3_client.list_objects_v2(
    bucket: bucket_name, max_keys: 5).contents
      if objects.count.zero?
        puts "No objects in bucket '#{bucket_name}'."
        return
      else
        objects.each do |object|
          puts object.key
        end
      end
    end

  when 'rename'
    if file == nil && new_name == nil
      puts "You must enter a file name and the new name of that file to rename!"
      exit
    else
      file_name=File.basename file 
      s3_client.copy_object(bucket: bucket_name,
                   copy_source: "#{bucket_name}/#{file_name}",
                   key: new_name)

      s3_client.delete_object(bucket: bucket_name,
                     key: file_name)
    end

else
  puts "Unknown operation: '%s'!" % operation
  puts USAGE
end