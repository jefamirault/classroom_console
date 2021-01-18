module ExportHelper
  DIRECTORY = "tmp/storage"

  def read_json(filename)
    path = "#{DIRECTORY}/#{filename}"
    if File.file? path
      JSON.parse File.read(path)
    else
      puts "File \"#{path}\" does not exist"
      nil
    end
  end

  def write_json(json, filename)
    path = "#{DIRECTORY}/#{filename}"
    puts "Writing to #{path}...".green
    File.open(path, 'w+') do |f|
      f.write JSON.pretty_generate(json)
    end
  end


  def read_object(filename)
    path = "#{DIRECTORY}/#{filename}"
    if File.file?(path)
      File.open(path) do |f|
        @object = Marshal.load(f)
      end
      @object
    else
      nil
    end
  end

  def write_object(object, filename)
    path = "#{DIRECTORY}/#{filename}"
    puts "Writing to #{path}..."
    File.open(path, 'w+') do |f|
      Marshal.dump(object, f)
    end
  end

end