require 'aws-sdk'
require 'aws-sdk-s3'
require 'pathname'
require 'aws-sdk-dynamodb'

#Command Line argument work
NO_SUCH_BUCKET = "The bucket '%s' does not exist!"

USAGE = <<DOC

Usage: ruby app.rb [bucket_name] [operation] [file name]

Where:

bucket_name (required) is the name of the bucket = meusick-bucket

operation(required) is the operation to perform on the bucket:

  To Upload a Song to S3 and DynamoDb: put_song                 
  To Upload a Album to S3 and DynamoDb: put_album               
  To Upload a Artist to S3 and DynamoDb: put_artist                

file_name   is the name of the file to upload, which can be a File path or a filename
            required when operation is 'upload'

Commands: 

Add a Song: ruby app.rb [bucket name] put_song [file name]
Add a Album: ruby app.rb [bucket name] put_album [file name]
Add a Artist: ruby app.rb [bucket name] put_artist [file name]

DOC

#assume the role
role_credentials = Aws::AssumeRoleCredentials.new(
  client: Aws::STS::Client.new,
  role_arn: "arn:aws:iam::589772831734:role/meusick-api-node-dev-us-east-1-lambdaRole",
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

def add_item_to_table(dynamodb_client, table_item)
  dynamodb_client.put_item(table_item)
  puts "Added song '#{table_item[:item][:pk]} " \
    "(#{table_item[:item][:sk]})'."
rescue StandardError => e
  puts "Error adding song '#{table_item[:item][:pk]} " \
    "(#{table_item[:item][:sk]})': #{e.message}"
end

def prepare_entry(obj_type, genre_name: nil, artist_name: nil, album_name: nil, song_name: nil, song_path: nil)
  region = 'us-east-1'
  table_name = 'music'
  genre = genre_name
  artist = artist_name
  album = album_name
  song = song_name 
  song_path = song_path

  Aws.config.update(
    region: region
  )

  dynamodb_client = Aws::DynamoDB::Client.new

  if obj_type == "song_by_album"
		item = {
			pk: "album##{album}",
			sk: "song##{song}",
			info: {
			genre: genre,
			artist: artist,
			albums: album,
			song: song_path
			}
		}
	elsif obj_type == "song_by_name"
		item = {
			pk: "song",
			sk: "song##{song}",
			info: {
			genre: genre,
			artist: artist,
			albums: album,
      song: song_path
			}
		}
  elsif obj_type == "album"
		item = {
			pk: "artist##{artist}",
			sk: "album##{album}",
			info: {
			genre: genre,
			artist: artist,
			albums: album,
			song: song
			}
		}
  elsif obj_type == "artist"
		item = {
			pk: "genre##{genre}",
			sk: "artist##{artist}",
			info: {
			genre: genre,
			artist: artist,
			albums: album,
			song: song
			}
		}
  elsif obj_type == "genre"
		item = {
			pk: "genre",
			sk: genre,
			info: {
			}
		}
  end

  # item = {
  #   pk: genre,
  #   sk: artist,
  #     album: album,
  #     song: song
  # }

  table_item = {
    table_name: table_name,
    item: item
  }

  puts "Adding Song '#{item[:pk]} (#{item[:sk]})' " \
    "to table '#{table_name}'..."
  add_item_to_table(dynamodb_client, table_item)
end


# "Now we're making the Neeww Version":
case operation

#When adding a new song
when 'put_song'
  if file == nil
    puts "You must enter a Song name!"
    exit
  else
    prepare_entry("song_by_name", song_name: file)
  
    puts "Adding: #{file}..."
    s3_client.put_object({
      bucket: bucket_name, 
      key: file
    })
    puts "Song successfully Added, YOU DID IT!"
  end

#When adding a new Album:
when 'put_album'
	if file == nil
    puts "You must enter an Album name!"
    exit
  else
    folder_name = File.basename(file, ".*")
    prepare_entry("album", album_name: folder_name)

    Dir.each_child(file) do |filename|
      next if filename == '.' or filename == '..'
      puts "Adding: #{folder_name}#{filename}..."
      prepare_entry("song_by_album", album_name: folder_name, song_name: filename)
      prepare_entry("song_by_name", album_name: folder_name, song_name: filename)
      s3_client.put_object({ bucket: bucket_name, key: "#{folder_name}/#{filename}"})
    end
    puts "SUCCESS: Album'#{folder_name}' successfuly uploaded to bucket '#{bucket_name}'."
  end

#When adding a new Artist:
when 'put_artist'
  if file == nil
    puts "You must enter an Artist name!"
    exit
  else
    puts "What is the song Genre?"
    genre_name = STDIN.gets.chomp

    folder_name = File.basename(file, ".*")
    artist = Pathname(folder_name)
    prepare_entry("artist", artist_name: folder_name, genre_name: genre_name)
    prepare_entry("genre", artist_name: folder_name, genre_name: genre_name)
    
    albums = artist.children()

    albums.each do |album| 
      if album.directory? 
        songs = Dir.each_child(album)
        album_path = album.to_s.split('/')
        prepare_entry("album", artist_name: folder_name, album_name: album_path[1])
        Dir.each_child(album) do |song_names|
          prepare_entry("song_by_album", artist_name: folder_name, album_name: album_path[1], song_name: song_names.to_s, song_path: "#{album}/#{song_names}")
          prepare_entry("song_by_name", artist_name: folder_name, album_name: album_path[1], song_name: song_names.to_s, song_path: "#{album}/#{song_names}")
          puts "Adding: #{album}/#{song_names}..."
          s3_client.put_object( bucket: bucket_name, key: "#{album}/#{song_names}")
        end
      end
    end   
    puts "SUCCESS: Artist'#{folder_name}' successfuly uploaded to bucket '#{bucket_name}'."   
  end


when 'put'
  puts "what is the upload type?"
  obj_type = STDIN.gets.chomp

  puts "What is the Song Name?"
  song_name = STDIN.gets.chomp

  puts "what is the song Album Name?"
  album_name = STDIN.gets.chomp

  puts "what is the song Artist Name?"
  artist_name = STDIN.gets.chomp

  puts "what is the song Genre Name?"
  genre_name = STDIN.gets.chomp

  prepare_entry(obj_type, genre_name, artist_name, album_name, song_name)


else
  puts "Unknown operation: '%s'!" % operation
end


#OLD OPERATIONS FROM 1st CLI ASSIGNMENT
#Different the operation name matches ARGV[1]
# case operation
# #To upload a file to the s3 bucket
# when 'upload'
#   if file == nil
#     puts "You must enter a file name to upload to S3!"
#     exit
#   else
#     file_name= File.basename file
#     s3_client.put_object( bucket: bucket_name, key: file_name)
#     puts "SUCCESS: File '#{file_name}' successfuly uploaded to bucket '#{bucket_name}'."
#   end

# #To upload a folder/alum/directory
# when 'upload_artist'
#   if file == nil
#     puts "You must enter a folder path to upload to S3!"
#     exit
#   else
#     folder_name = File.basename(file, ".*")
#     path_names = Pathname(folder_name).each_child {|inner_file| 
#     if inner_file.directory? 
#       Dir.each_child(inner_file) do |song_names|
#         s3_client.put_object( bucket: bucket_name, key: "#{inner_file}/#{song_names}")
#       end      
#     end
# }
#     puts "SUCCESS: Artist'#{folder_name}' successfuly uploaded to bucket '#{bucket_name}'."
#   end

# #To upload an album
# when 'upload_album'
#   if file == nil
#     puts "You must enter a folder path to upload to S3!"
#     exit
#   else
#     folder_name = File.basename(file, ".*")
#     Dir.each_child(file) do |filename|
#       next if filename == '.' or filename == '..'
#       s3_client.put_object( bucket: bucket_name, key: "#{folder_name}/#{filename}")
#     end
#     puts "SUCCESS: Album'#{folder_name}' successfuly uploaded to bucket '#{bucket_name}'."
#   end

# #To list the objects inside of a bucket
# when 'list'
#   if bucket_name == nil
#     puts "You must enter a Bucket-name!"
#     exit
#   else
#     puts "Contents of '%s':" % bucket_name
#     objects = s3_client.list_objects_v2(
#     bucket: bucket_name, max_keys: 10).contents
#       if objects.count.zero?
#         puts "No objects in bucket '#{bucket_name}'."
#         return
#       else
#         objects.each do |object|
#           puts object.key
#         end
#       end
#     end

# #To rename an existing object inside of a bucket
# when 'rename'
#   if file == nil && new_name == nil
#     puts "You must enter a file name and the new name of that file to rename!"
#     exit
#   else
#     file_name=File.basename file 
#     s3_client.copy_object(bucket: bucket_name,
#                   copy_source: "#{bucket_name}/#{file_name}",
#                   key: new_name)

#     s3_client.delete_object(bucket: bucket_name,
#                     key: file_name)
#     puts "SUCCESS: File '#{file_name}' successfuly changed name to '#{new_name}'."
#   end