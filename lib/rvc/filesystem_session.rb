module RVC

class FilesystemSession
  def initialize name
    fail "invalid session name" unless name =~ /^[\w-]+$/
    @dir = File.join(ENV['HOME'], '.rvc', 'sessions', name)
    prev_umask = File.umask 077
    FileUtils.mkdir_p @dir
    FileUtils.mkdir_p mark_dir
    FileUtils.mkdir_p connection_dir
    File.umask prev_umask
    @priv = {}
  end

  def marks
    Dir.entries(mark_dir).reject { |x| x == '.' || x == '..' } + @priv.keys
  end

  def get_mark key
    if is_private_mark? key
      @priv[key]
    else
      return nil unless File.exists? mark_fn(key)
      File.readlines(mark_fn(key)).
        map { |path| RVC::Util.lookup(path.chomp) }.
        inject([], &:+)
    end
  end

  def set_mark key, objs
    if is_private_mark? key
      if objs == nil
        @priv.delete key
      else
        @priv[key] = objs
      end
    else
      if objs == nil
        File.unlink mark_fn(key)
      else
        File.open(mark_fn(key), 'w') do |io|
          objs.each { |obj| io.puts obj.rvc_path_str }
        end
      end
    end
  end

  def connections
    Dir.entries(connection_dir).reject { |x| x == '.' || x == '..' }
  end

  def get_connection key
    return nil unless File.exists? connection_fn(key)
    File.open(connection_fn(key)) { |io| YAML.load io }
  end

  def set_connection key, conn
    if conn == nil
      File.unlink(connection_fn(key))
    else
      File.open(connection_fn(key), 'w') { |io| YAML.dump conn, io }
    end
  end

  private

  def is_private_mark? key
    return key == '' ||
           key == '~' ||
           key == '@' ||
           key =~ /^\d+$/
  end

  def mark_dir; File.join(@dir, 'marks') end
  def mark_fn(key); File.join(mark_dir, key) end
  def connection_dir; File.join(@dir, 'connections') end
  def connection_fn(key); File.join(connection_dir, key) end
end

end

