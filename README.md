# S3 Uploader

## A program that supports my content team's access to albums, music, and artists files 

This program is run from your terminal/command line and requires only that you know the name of the bucket you are accessing.
If for some reason you do not know which bucket to work with, you can run 
```ruby app.rb``` and you will see a list of all the buckets available for you to edit. 
The main bucket is "meusick-bucket" 

## Getting Started

### Dependencies

* Must be able to run a ruby program and have aws credentials that are trusted entities of the role created

### Installing

* How/where to download your program
* Any modifications needed to be made to files/folders

### Executing program

* How to run the program

To list the objects in an s3 bucket:
```
ruby app.rb meusick-bucket list
```
To upload an object to an s3 bucket:
```
ruby app.rb meusick-bucket upload [FILE_NAME] or [FILE_PATH]
```
To upload a folder/album/artist:
```
ruby app.rb meusick-bucket upload_folder [FOLDER_NAME] or [FOLDER_PATH] 
```

To rename an existing file:
```
ruby app.rb meusick-bucket rename [FILE_NAME_EXISTING] [NEW_NAME_OF_FILE]
```

## Authors

Kristen Orue  
[@Kristen](https://github.com/KristenOrue/s3_upload)

## Version History

* 0.1
    * Initial Release

## License

This project is licensed under the Kristen Orue License - see the LICENSE.md file for details

## Acknowledgments

Inspiration, code snippets, etc.
* [command-line help](https://docs.aws.amazon.com/sdk-for-ruby/v3/developer-guide/hello.html)
* [upload_file support](https://docs.aws.amazon.com/sdk-for-ruby/v3/developer-guide/s3-example-upload-bucket-item.html)
* [Client-methods API](https://docs.aws.amazon.com/sdk-for-ruby/v2/api/Aws/S3/Client.html)
* [list_files support](https://docs.aws.amazon.com/code-samples/latest/catalog/ruby-s3-s3-ruby-example-list-bucket-items.rb.html)
* [developer-guide AWS CLIENT API](https://docs.aws.amazon.com/sdk-for-ruby/v3/developer-guide/aws-sdk-ruby-dg.pd)